package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.events.Event
import com.facebook.react.uimanager.events.RCTEventEmitter

class OnCameraShowEventOld(
    viewId: Int,
    private val isInit: Boolean
) : Event<OnCameraShowEvent>(viewId) {

    override fun getEventName(): String = EVENT_NAME

    override fun dispatch(rctEventEmitter: RCTEventEmitter) {
        rctEventEmitter.receiveEvent(
            this.viewTag,
            eventName,
            Arguments.createMap().apply {
                putBoolean("isInit", isInit)
            }
        )
    }

    companion object {
        const val EVENT_NAME = "topCameraShow"
    }
}
