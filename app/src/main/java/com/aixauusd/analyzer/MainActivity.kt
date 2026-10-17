package com.aixauusd.analyzer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.colorResource
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.aixauusd.analyzer.ui.dashboard.DashboardScreen
import com.aixauusd.analyzer.ui.dashboard.MainViewModel
import com.aixauusd.analyzer.ui.settings.SettingsScreen
import com.aixauusd.analyzer.ui.settings.SettingsViewModel
import dagger.hilt.android.AndroidEntryPoint

object NavRoutes {
    const val DASHBOARD = "dashboard"
    const val SETTINGS = "settings"
}

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = colorResource(R.color.bg_dark)
            ) {
                AppNavigation()
            }
        }
    }
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = NavRoutes.DASHBOARD
    ) {
        composable(NavRoutes.DASHBOARD) {
            val mainViewModel: MainViewModel = hiltViewModel()
            DashboardScreen(
                viewModel = mainViewModel,
                onNavigateToSettings = { navController.navigate(NavRoutes.SETTINGS) }
            )
        }
        composable(NavRoutes.SETTINGS) {
            val settingsViewModel: SettingsViewModel = hiltViewModel()
            SettingsScreen(
                viewModel = settingsViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
