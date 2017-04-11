//
//  ViewController.swift
//  BTMonitor
//
//  Created by Paul Wilkinson on 9/4/17.
//  Copyright © 2017 Paul Wilkinson. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var deviceCount: UILabel!
    @IBOutlet weak var connectSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .long
        return df
    }()
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<Connection>!
    
    fileprivate var btManager = BTManager.sharedManager
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: BTManager.connectionNotification, object: nil, queue: OperationQueue.main) { (notification) in
            if let status = notification.userInfo?["STATE"] as? Bool {
                self.deviceCount.textColor = status ? UIColor.green:UIColor.red
                self.deviceCount.text = "\(self.btManager.connectedDeviceCount)"
            }
        }
        
        self.setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.deviceCount.textColor = self.btManager.connectedState ? UIColor.green:UIColor.red
        self.deviceCount.text = "\(self.btManager.connectedDeviceCount)"
        self.connectSwitch.isOn = self.btManager.reconnectMode
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func setupFetchedResultsController() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Connection>(entityName: "Connection")
        let dateDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [dateDescriptor]
        
        fetchedResultsController = NSFetchedResultsController<Connection>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        tableView.reloadData()
    }
    
    @IBAction func switched(_ sender: UISwitch) {
        self.btManager.reconnectMode = sender.isOn
        UserDefaults.standard.set(sender.isOn, forKey: "ReconnectMode")
    }

}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return 0
        }
            return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let connection = fetchedResultsController.object(at: indexPath)

        var timeStamp = ""
        
        if let stampDate = connection.timeStamp as Date? {
            timeStamp = self.dateFormatter.string(from: stampDate)
        }
        

        cell.textLabel?.text = "\(connection.event!) - \(timeStamp)"
        
        return cell
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
    
}

