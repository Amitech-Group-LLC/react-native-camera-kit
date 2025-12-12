package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnCameraShowEvent(
    surfaceId: Int,
    viewId: Int,
    private val isInit: Boolean,
) : Event<OnCameraShowEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putBoolean("isInit", isInit)
        }

    companion object {
        const val EVENT_NAME = "topOnCameraShow"
    }
}
