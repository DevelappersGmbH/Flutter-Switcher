//
//  ViewController.swift
//  Switcher
//
//  Created by Schaban Bochi on 12.10.22.
//

import UIKit
import Flutter

class ViewController: UIViewController, UITableViewDataSource, BHApi { // implement BHApi
    private var history: [BHistoryEntry] = []
    // setup api for sending the status
    private var api: BFApi! 
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var switcher : UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // Setup api for incoming message
        BHApiSetup(appDelegate.engine.binaryMessenger, self)
        // setup api for outgoing message
        api = BFApi.init(binaryMessenger: appDelegate.engine.binaryMessenger)
    }
    
    @IBAction func switchDidChange(_ sender: UISwitch){
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = BHistoryEntry.make(withState: sender.isOn as NSNumber, at: formatter.string(from: Date.now), source: "IOS")
        addEntry(entry)
    }
    
    // The function to be called when the button 'Got to Flutter' is pressed
    @IBAction func goToFlutter(_ sender: UIButton){
        // send the status to Flutter
        api.currentStateState(switcher.isOn as NSNumber){ (error) in
            if let error = error {
                print(error)
            }
        }
        // Get the Flutter engine from the AppDelegate
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).engine
        // Create a FlutterViewController with the Flutter engine
        let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        // Present the FlutterViewController
        present(flutterViewController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell {
        let cell: HistoryCell = self.tableView.dequeueReusableCell(withIdentifier: "HistoryEntry") as! HistoryCell
        let info = history[indexPath.row]
        cell.status.text = info.state != 0 ? "True" : "False"
        cell.at.text = info.at
        cell.source.text = info.source
        return cell
    }
    
    // implement the function of BHApi to receive the status from Flutter and update the UI
    func addEntry(_ entry: BHistoryEntry){
        history.append(entry)
        tableView.reloadData()
    }
    
    func updateStateEntry(_ entry: BHistoryEntry, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        addEntry(entry)
        switcher.isOn = entry.state as! Bool
    }
    
}

