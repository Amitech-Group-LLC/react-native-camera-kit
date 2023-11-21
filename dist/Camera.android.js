import { __awaiter } from "tslib";
import React from 'react';
import { requireNativeComponent, findNodeHandle, NativeModules, processColor } from 'react-native';
const { RNCameraKitModule } = NativeModules;
const NativeCamera = requireNativeComponent('CKCameraManager');
const Camera = React.forwardRef((props, ref) => {
    const nativeRef = React.useRef();
    React.useImperativeHandle(ref, () => ({
        capture: (options = {}) => __awaiter(void 0, void 0, void 0, function* () {
            var _a;
            return yield RNCameraKitModule.capture(options, findNodeHandle((_a = nativeRef.current) !== null && _a !== void 0 ? _a : null));
        }),
        requestDeviceCameraAuthorization: () => {
            throw new Error('Not implemented');
        },
        checkDeviceCameraAuthorizationStatus: () => {
            throw new Error('Not implemented');
        },
    }));
    const transformedProps = Object.assign({}, props);
    transformedProps.ratioOverlayColor = processColor(props.ratioOverlayColor);
    transformedProps.frameColor = processColor(props.frameColor);
    transformedProps.laserColor = processColor(props.laserColor);
    return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...transformedProps}/>;
});
export default Camera;
//# sourceMappingURL=Camera.android.js.map