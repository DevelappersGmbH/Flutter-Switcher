package de.develappers.switcher

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.widget.SwitchCompat;
import de.develappers.switcher.bridge.HistoryEntry
import java.sql.Date
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : AppCompatActivity() {
   private lateinit var  switch : SwitchCompat;
    private lateinit var histories: MutableList<HistoryEntry>
    private lateinit var list: LinearLayout
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        switch = findViewById(R.id.switcher)
        list = findViewById(R.id.list)
        histories = mutableListOf()
        switch.setOnClickListener{
            updateSwitcher(switch.isChecked)
        }
        val button = findViewById<Button>(R.id.button)
        button.setOnClickListener {
            startActivity(FlutterSwitcherActivity.withState(this,switch.isChecked){state->
                addNewState(state)
                switch.isChecked = state.state
            })
        }
    }

    private fun updateSwitcher(state: Boolean){
        val historyEntry = HistoryEntry.Builder()
        historyEntry.setState(state)
        historyEntry.setSource("Android")
        val sdf = SimpleDateFormat("hh:mm:ss")
        val currentDate = sdf.format(Calendar.getInstance().time)
        historyEntry.setAt(currentDate)
        val entry = historyEntry.build()
        addNewState(entry)
    }

    private fun addNewState(entry:HistoryEntry){
        histories.add(entry)
        val card = layoutInflater.inflate(R.layout.history_entry, null)
        card.findViewById<TextView>(R.id.state).text = entry.state.toString()
        card.findViewById<TextView>(R.id.at).text = entry.at
        card.findViewById<TextView>(R.id.source).text = entry.source
        list.addView(card)
    }

}