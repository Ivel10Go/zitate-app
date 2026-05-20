package com.quotidian.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
	}

	override fun onNewIntent(intent: android.content.Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		val route = intent.getStringExtra("launch_route")?.takeIf { it.isNotBlank() }
		if (route != null) {
			flutterEngine?.navigationChannel?.pushRoute(route)
		}
	}

	override fun getInitialRoute(): String {
		val route = intent?.getStringExtra("launch_route")
		return route?.takeIf { it.isNotBlank() } ?: super.getInitialRoute() ?: "/"
	}
}
