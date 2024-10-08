package com.rncamerakit

import android.graphics.Color
import android.util.Log
import androidx.annotation.ColorInt
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableType
import com.facebook.react.common.MapBuilder
import com.facebook.react.common.ReactConstants.TAG
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp


class CKCameraManager : SimpleViewManager<CKCamera>() {

    override fun getName() : String {
        return "CKCameraManager"
    }

    override fun createViewInstance(context: ThemedReactContext): CKCamera {
        return CKCamera(context)
    }

    override fun receiveCommand(view: CKCamera, commandId: String?, args: ReadableArray?) {
        var logCommand = "CameraManager received command $commandId("
        for (i in 0..(args?.size() ?: 0)) {
            if (i > 0) {
                logCommand += ", "
            }
            logCommand += when (args?.getType(0)) {
                ReadableType.Null -> "Null"
                ReadableType.Array -> "Array"
                ReadableType.Boolean -> "Boolean"
                ReadableType.Map -> "Map"
                ReadableType.Number -> "Number"
                ReadableType.String -> "String"
                else ->  ""
            }
        }
        logCommand += ")"
        Log.d(TAG, logCommand)
    }

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
        return MapBuilder.of(
                "onOrientationChange", MapBuilder.of("registrationName", "onOrientationChange"),
                "onReadCode", MapBuilder.of("registrationName", "onReadCode"),
                "onCameraShow", MapBuilder.of("registrationName", "onCameraShow"),
                "onPictureTaken", MapBuilder.of("registrationName", "onPictureTaken"),
                "onZoom", MapBuilder.of("registrationName", "onZoom")
        )
    }

    @ReactProp(name = "cameraType")
    fun setCameraType(view: CKCamera, type: String) {
        view.setCameraType(type)
    }

    @ReactProp(name = "initBarCodeTypes")
    fun setInitBarCodeTypes(view: CKCamera, types: ReadableArray?) {

        val barCodeTypes = ArrayList<String>()
        if(types != null && types.size() > 0){
            for (i in 0 until types.size()) {
                val type = types.getString(i)
                type?.let {
                    barCodeTypes.add(it)
                }
            }
        }
        
        view.setInitBarCodeTypes(barCodeTypes.toTypedArray())
    }

    @ReactProp(name = "flashMode")
    fun setFlashMode(view: CKCamera, mode: String?) {
        view.setFlashMode(mode)
    }

    @ReactProp(name = "torchMode")
    fun setTorchMode(view: CKCamera, mode: String?) {
        view.setTorchMode(mode)
    }

    @ReactProp(name = "focusMode")
    fun setFocusMode(view: CKCamera, mode: String) {
        view.setAutoFocus(mode)
    }

    @ReactProp(name = "zoomMode")
    fun setZoomMode(view: CKCamera, mode: String?) {
        view.setZoomMode(mode)
    }

    @ReactProp(name = "zoom", defaultDouble = -1.0)
    fun setZoom(view: CKCamera, factor: Double) {
        view.setZoom(if (factor == -1.0) null else factor)
    }

    @ReactProp(name = "maxZoom", defaultDouble = 420.0)
    fun setMaxZoom(view: CKCamera, factor: Double) {
        view.setMaxZoom(factor)
    }

    @ReactProp(name = "scanThrottleDelay", defaultInt = 2000)
    fun setScanThrottleDelay(view: CKCamera, factor: Int) {
        view.setScanThrottleDelay(factor)
    }

    @ReactProp(name = "scanBarcode")
    fun setScanBarcode(view: CKCamera, enabled: Boolean) {
        view.setScanBarcode(enabled)
    }

    @ReactProp(name = "showFrame")
    fun setShowFrame(view: CKCamera, enabled: Boolean) {
        view.setShowFrame(enabled)
    }

    @ReactProp(name = "laserColor", defaultInt = Color.RED)
    fun setLaserColor(view: CKCamera, @ColorInt color: Int) {
        view.setLaserColor(color)
    }

    @ReactProp(name = "frameColor", defaultInt = Color.GREEN)
    fun setFrameColor(view: CKCamera, @ColorInt color: Int) {
        view.setFrameColor(color)
    }

    @ReactProp(name = "outputPath")
    fun setOutputPath(view: CKCamera, path: String) {
        view.setOutputPath(path)
    }

    @ReactProp(name = "shutterAnimationDuration")
    fun setShutterAnimationDuration(view: CKCamera, duration: Int) {
        view.setShutterAnimationDuration(duration)
    }

    @ReactProp(name = "shutterPhotoSound")
    fun setShutterPhotoSound(view: CKCamera, enabled: Boolean) {
        view.setShutterPhotoSound(enabled);
    }
}
