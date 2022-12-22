package de.develappers.switcher;

import android.content.ComponentCallbacks
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import de.develappers.switcher.MyApplication.Companion.ENGINE_ID
import de.develappers.switcher.bridge.HistoryEntry
import io.flutter.embedding.engine.FlutterEngine

class FlutterSwitcherActivity : FlutterActivity() {

    companion object {
        private const val STATE_VALUE = "state_value"
        lateinit var callBack : (result: HistoryEntry)-> Unit // callback function to add the history entry to the list

        fun withState(context: Context, state: Boolean, stateCallBack: (result: HistoryEntry)-> Unit) : Intent{
            this.callBack = stateCallBack;
            // create a new instance of the CachedEngineSwitcherIntent and pass the state to it
            return CachedEngineSwitcherIntentBuilder(ENGINE_ID).build(context).putExtra(STATE_VALUE, state)
        }
    }

    class CachedEngineSwitcherIntentBuilder(engineId: String) :
        CachedEngineIntentBuilder(FlutterSwitcherActivity::class.java, engineId) {}

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // get the state from the intent
        var state = intent.getBooleanExtra(STATE_VALUE, true)
        // create a new instance of the ApiHandler and pass the state to it to update the state of the switcher in flutter
        bridge.FApi(flutterEngine.dartExecutor).currentState(state){}
        // create a new instance of the ApiHandler
        bridge.HApi.setup(flutterEngine.dartExecutor, ApiHandler())
    }

    // The HApi implementation to receive the history entry from flutter and add it to the list
    inner class ApiHandler : bridge.HApi{
        override fun updateState(entry: bridge.HistoryEntry) {
            callBack.invoke(entry)
        }
    }
}