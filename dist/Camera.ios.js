import { __awaiter } from "tslib";
import React from 'react';
import { requireNativeComponent, NativeModules } from 'react-native';
const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');
const Camera = React.forwardRef((props, ref) => {
    const nativeRef = React.useRef();
    React.useImperativeHandle(ref, () => ({
        capture: () => __awaiter(void 0, void 0, void 0, function* () {
            return yield CKCameraManager.capture({});
        }),
        requestDeviceCameraAuthorization: () => __awaiter(void 0, void 0, void 0, function* () {
            return yield CKCameraManager.checkDeviceCameraAuthorizationStatus();
        }),
        checkDeviceCameraAuthorizationStatus: () => __awaiter(void 0, void 0, void 0, function* () {
            return yield CKCameraManager.checkDeviceCameraAuthorizationStatus();
        }),
    }));
    return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...props}/>;
});
Camera.defaultProps = {
    resetFocusTimeout: 0,
    resetFocusWhenMotionDetected: true,
};
export default Camera;
//# sourceMappingURL=Camera.ios.js.map