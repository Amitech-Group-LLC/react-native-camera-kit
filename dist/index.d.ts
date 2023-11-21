import Camera from './Camera';
import { CameraApi, CameraType, CaptureData, FlashMode, FocusMode, TorchMode, ZoomMode } from './types';
declare const CameraKit: any;
export declare const Orientation: {
    PORTRAIT: number;
    LANDSCAPE_LEFT: number;
    PORTRAIT_UPSIDE_DOWN: number;
    LANDSCAPE_RIGHT: number;
};
export default CameraKit;
export { Camera, CameraType, TorchMode, FlashMode, FocusMode, ZoomMode, CameraApi, CaptureData };
