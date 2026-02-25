package com.codecarrots.korlinks

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.codecarrots.korlinks/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchFacebook" -> {
                    val id = call.argument<String>("id")
                    if (id == null) {
                        result.error("INVALID_ID", "Facebook ID cannot be null", null)
                        return@setMethodCallHandler
                    }
                    val url = "https://www.facebook.com/$id"
                    launchApp("com.facebook.katana", url, result)
                }

                "launchInstagram" -> {
                    val username = call.argument<String>("username")
                    if (username == null) {
                        result.error("INVALID_USERNAME", "Instagram username cannot be null", null)
                        return@setMethodCallHandler
                    }
                    val url = "https://www.instagram.com/$username"
                    launchApp("com.instagram.android", url, result)
                }

                "launchYouTube" -> {
                    val videoId = call.argument<String>("videoId")
                    if (videoId == null) {
                        result.error("INVALID_VIDEO_ID", "YouTube video ID cannot be null", null)
                        return@setMethodCallHandler
                    }
                    val url = "https://www.youtube.com/watch?v=$videoId"
                    launchApp("com.google.android.youtube", url, result)
                }

                "launchWhatsApp" -> {
                    val phone = call.argument<String>("phone")
                    if (phone == null) {
                        result.error("INVALID_PHONE", "Phone number cannot be null", null)
                        return@setMethodCallHandler
                    }
                    val url = "https://wa.me/$phone"
                    launchApp("com.whatsapp", url, result)
                }

                "launchUrl" -> {
                    val url = call.argument<String>("url")
                    launchAnyUrl(url, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun launchApp(packageName: String, url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("INVALID_URL", "URL cannot be null", null)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            setPackage(packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
            } else {
                // App not installed, fallback to browser
                val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallbackIntent)
            }
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("ACTIVITY_NOT_FOUND", "Could not open $packageName", e.message)
        }
    }

    private fun launchAnyUrl(url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("INVALID_URL", "URL cannot be null", null)
            return
        }

        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("ACTIVITY_NOT_FOUND", "Could not open URL", e.message)
        }
    }
}
