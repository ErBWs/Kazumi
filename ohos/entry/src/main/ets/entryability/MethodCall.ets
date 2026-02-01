import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodChannel,
  MethodResult
} from "@ohos/flutter_ohos";
import { common, Want, wantConstant } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { window } from "@kit.ArkUI";
import { fileUri } from '@kit.CoreFileKit';
import { deviceInfo } from '@kit.BasicServicesKit';

export default class MethodCallPlugin implements FlutterPlugin, AbilityAware {
  private channel?: MethodChannel;
  private deviceType: string = deviceInfo.deviceType;
  private context?: common.UIAbilityContext;

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.predidit.kazumi/intent");
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult) => {
        switch (call.method) {
          case "openWithMime":
            let url = String(call.argument("url"));
            let mimeType = String(call.argument("mimeType"));
            this.openWithMime(url, mimeType);
            result.success("");
            break;
          case "enterFullscreen":
            let needSet = Boolean(call.argument("needSet"));
            this.enterFullScreen(needSet);
            result.success("");
            break;
          case "exitFullscreen":
            this.exitFullScreen();
            result.success("");
            break;
          case "checkOhosIsDesktop":
            let isDesktop = this.checkOhosDesktop();
            result.success(isDesktop);
            break;
          case "openWithInstaller":
            let path = String(call.argument("path"));
            this.openWithInstaller(path);
            result.success("");
            break;
          default:
            result.notImplemented();
            break;
        }
      }
    })
  }

  private openWithMime(url: string, mimeType: string): void {
    let want: Want = {
      action: 'ohos.want.action.viewData',
      uri: url,
      type: mimeType,
    };
    this.context?.startAbility(want, (err: BusinessError) => {
      if (err.code) {
        console.error(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
      }
    });
  }

  private enterFullScreen(needSet: boolean): void {
    window.getLastWindow(this.context).then((lastWindow) => {
      lastWindow.setSpecificSystemBarEnabled("status", false, true);
      lastWindow.setSpecificSystemBarEnabled("navigationIndicator", false, true);
      lastWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_LANDSCAPE);
      lastWindow.enableLandscapeMultiWindow();
      lastWindow.maximize();
    })
  }

  private exitFullScreen(): void {
    window.getLastWindow(this.context).then((lastWindow) => {
      lastWindow.setSpecificSystemBarEnabled("status", true, true);
      lastWindow.setSpecificSystemBarEnabled("navigationIndicator", true, true);
      lastWindow.setPreferredOrientation(window.Orientation.USER_ROTATION_PORTRAIT);
      lastWindow.disableLandscapeMultiWindow();
      lastWindow.recover();
    })
  }

  private checkOhosDesktop(): boolean {
    return this.deviceType == '2in1';
  }

  private async openWithInstaller(path: string): Promise<void> {
    let want: Want = {
      // Hardcode bundle name
      bundleName: 'com.xiaobai.hap_installer',
      action: 'ohos.want.action.viewData',
      uri: fileUri.getUriFromPath(path),
      flags: wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
    };
    this.context?.startAbility(want, (err: BusinessError) => {
      if (err.code) {
        console.error(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
      }
    });
  }

  getUniqueClassName(): string {
    return "MethodCallPlugin"
  }

  onDetachedFromAbility(): void {
  }

  onDetachedFromEngine(): void {
    this.channel?.setMethodCallHandler(null);
  }
}