package com.adobe.marketing.mobile.flutter.flutter_aepmessaging

import android.os.Handler
import android.os.Looper
import com.adobe.marketing.mobile.*
import com.adobe.marketing.mobile.messaging.Proposition
import com.adobe.marketing.mobile.messaging.PropositionItem
import com.adobe.marketing.mobile.messaging.Surface
import com.adobe.marketing.mobile.services.ServiceProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** FlutterAEPMessagingPlugin */
class FlutterAEPMessagingPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var messageCache = mutableMapOf<String, Message>()
  // Cache of PropositionItems by itemId, kept alive so tracking calls from Dart
  // can be routed to the original native object (preserving tracking XDM fidelity).
  private var propositionItemCache = mutableMapOf<String, PropositionItem>()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_aepmessaging")
    channel.setMethodCallHandler(this)
    ServiceProvider.getInstance().uiService.setPresentationDelegate(FlutterAEPMessagingDelegate(messageCache, channel))
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      // Messaging Methods
      "extensionVersion" -> result.success(Messaging.extensionVersion())
      "getCachedMessages" -> this.getCachedMessages(result)
      "refreshInAppMessages" -> this.refreshInAppMessages(result)
      // Content Card / Surfaces Methods
      "updatePropositionsForSurfaces" -> this.updatePropositionsForSurfaces(call, result)
      "getPropositionsForSurfaces" -> this.getPropositionsForSurfaces(call, result)
      "trackPropositionInteraction" -> this.trackPropositionInteraction(call, result)
      "generatePropositionInteractionXdm" -> this.generatePropositionInteractionXdm(call, result)
      // Message Methods
      "clearMessage" -> this.clearMessage(call, result)
      "dismissMessage" -> this.dismissMessage(call, result)
      "setAutoTrack" -> this.setAutoTrack(call, result)
      "showMessage" -> this.showMessage(call, result)
      "trackMessage" -> this.trackMessage(call, result)
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun getCachedMessages(result: Result) {
    val cachedMessages = messageCache.values.map {
        message -> mapOf("id" to message.id, "autoTrack" to message.autoTrack)
    }.toList()
    result.success(cachedMessages)
  }

  private fun refreshInAppMessages(result: Result) {
    Messaging.refreshInAppMessages()
    result.success(null)
  }

  // Message Class Functions
  private fun clearMessage(call: MethodCall, result: Result) {
    val messageId = call.argument<String>("id")
    messageCache.remove(messageId)
    result.success(null)
  }

  private fun dismissMessage(call: MethodCall, result: Result) {
    val messageId = call.argument<String>("id")
    messageCache[messageId]?.dismiss()
    result.success(null)
  }

  private fun setAutoTrack(call: MethodCall, result: Result) {
    val id = call.argument<String>("id")
    val shouldAutoTrack = call.argument<Boolean>("autoTrack")
    messageCache[id]?.autoTrack = shouldAutoTrack as Boolean
    result.success(null)
  }

  private fun showMessage(call: MethodCall, result: Result) {
    val id = call.argument<String>("id")
    messageCache[id]?.show()
    result.success(null)
  }

  private fun trackMessage(call: MethodCall, result: Result) {
    val eventType = call.argument<Int>("eventType")
    val interaction = call.argument<String>("interaction")
    val messageId = call.argument<String>("id")
    val message = messageCache[messageId]
    if (message != null) {
      message.track(interaction, convertToMessagingEventType(eventType as Int))
      result.success(null)
    }
  }

  // Content Card / Surfaces Functions
  @Suppress("UNCHECKED_CAST")
  private fun surfacesFromArgs(call: MethodCall): List<Surface> {
    val list = call.argument<List<Map<String, Any>>>("surfaces") ?: emptyList()
    return list.mapNotNull { item ->
      val path = item["path"] as? String
      if (!path.isNullOrEmpty()) Surface(path) else null
    }
  }

  private fun updatePropositionsForSurfaces(call: MethodCall, result: Result) {
    Messaging.updatePropositionsForSurfaces(surfacesFromArgs(call))
    result.success(null)
  }

  private fun getPropositionsForSurfaces(call: MethodCall, result: Result) {
    Messaging.getPropositionsForSurfaces(surfacesFromArgs(call)) { propositionsMap ->
      val encoded = HashMap<String, Any>()
      propositionsMap?.forEach { (surface, propositions) ->
        encoded[surface.uri] = propositions.map { proposition ->
          // Keep each PropositionItem alive so tracking calls can reach it later.
          proposition.items.forEach { item -> propositionItemCache[item.itemId] = item }
          mapFromProposition(proposition)
        }
      }
      Handler(Looper.getMainLooper()).post { result.success(encoded) }
    }
  }

  @Suppress("UNCHECKED_CAST")
  private fun mapFromProposition(proposition: Proposition): Map<String, Any> {
    val map = HashMap<String, Any>()
    map["id"] = proposition.uniqueId
    map["scope"] = proposition.scope
    val scopeDetails = proposition.toEventData()["scopeDetails"]
    map["scopeDetails"] = (scopeDetails as? Map<String, Any>) ?: HashMap<String, Any>()
    map["items"] = proposition.items.map { mapFromPropositionItem(it) }
    return map
  }

  private fun mapFromPropositionItem(item: PropositionItem): Map<String, Any> {
    val map = HashMap<String, Any>()
    map["itemId"] = item.itemId
    map["schema"] = item.schema?.toString() ?: ""
    map["data"] = item.itemData ?: HashMap<String, Any>()
    return map
  }

  private fun trackPropositionInteraction(call: MethodCall, result: Result) {
    val itemId = call.argument<String>("itemId")
    val eventType = call.argument<Int>("eventType")
    val interaction = call.argument<String>("interaction")
    val tokens = call.argument<List<String>>("tokens")
    val item = propositionItemCache[itemId]
    if (item != null && eventType != null) {
      item.track(interaction, convertToMessagingEventType(eventType), tokens)
    }
    result.success(null)
  }

  private fun generatePropositionInteractionXdm(call: MethodCall, result: Result) {
    val itemId = call.argument<String>("itemId")
    val eventType = call.argument<Int>("eventType")
    val interaction = call.argument<String>("interaction")
    val tokens = call.argument<List<String>>("tokens")
    val item = propositionItemCache[itemId]
    if (item != null && eventType != null) {
      result.success(
        item.generateInteractionXdm(interaction, convertToMessagingEventType(eventType), tokens)
      )
    } else {
      result.success(null)
    }
  }

  private fun convertToMessagingEventType(value: Int): MessagingEdgeEventType {
    return when (value) {
      0 -> MessagingEdgeEventType.DISMISS
      1 -> MessagingEdgeEventType.INTERACT
      2 -> MessagingEdgeEventType.TRIGGER
      3 -> MessagingEdgeEventType.DISPLAY
      4 -> MessagingEdgeEventType.PUSH_APPLICATION_OPENED
      5 -> MessagingEdgeEventType.PUSH_CUSTOM_ACTION
      else -> MessagingEdgeEventType.DISMISS
    }
  }
}