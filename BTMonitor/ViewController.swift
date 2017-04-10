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

    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .long
        return df
    }()
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<Connection>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: BTManager.connectionNotification, object: nil, queue: OperationQueue.main) { (notification) in
            if let status = notification.userInfo?["STATE"] as? Bool {
                self.statusView.backgroundColor = status ? UIColor.green:UIColor.red
            }
        }
        
        self.setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let connectionState = BTManager.sharedManager.connectedState
        self.statusView.backgroundColor = connectionState ? UIColor.green:UIColor.red
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func setupFetchedResultsController() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Connection>(entityName: "Connection")
        let dateDescriptor = NSSortDescriptor(key: "connectTime", ascending: false)
        
        fetchRequest.sortDescriptors = [dateDescriptor]
        
        fetchedResultsController = NSFetchedResultsController<Connection>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        try! fetchedResultsController.performFetch()
        tableView.reloadData()
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
        
        var startTime = ""
        
        if let startDate = connection.connectTime as Date? {
            startTime = self.dateFormatter.string(from: startDate)
        }
        
        var endTime = ""
        
        if let endDate = connection.disconnectTime as Date? {
            endTime = self.dateFormatter.string(from: endDate)
        }
        

            cell.detailTextLabel?.text = "\(connection.bgTime)"
    

        cell.textLabel?.text = "\(startTime) - \(endTime)"
        
        return cell
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
    
}

