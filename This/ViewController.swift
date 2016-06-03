//
//  ViewController.swift
//  This
//
//  Created by User 2 on 6/3/16.
//  Copyright © 2016 User 2. All rights reserved.
//

import UIKit
import MapKit
import Foundation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    private var locationManager = CLLocationManager()
    private var dataPoints:[DataPoints] = [DataPoints]()
    let dateFormatter = NSDateFormatter()
    var crimedate:String!
    var currentValue:Int!
    let startLocation = CLLocation(latitude:42.308038, longitude:-88.9980337)
    let initialRadius:CLLocationDistance = 20000
    
    
    
    
    @IBOutlet weak var navigtionBar: UINavigationBar!
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lblCrimeRange: UILabel!
    
    @IBAction func DateSlider(sender: UISlider) {
        
        currentValue = Int(sender.value)
        lblCrimeRange.text = "\(currentValue) Days Ago Until Now."
        
    }

    @IBAction func DateSliderUP(sender: UISlider) {
        
        currentValue = Int(sender.value)
        let now = NSDate()
        mapView.removeAnnotations(mapView.annotations)
        
        var i = 1
        while i <= currentValue{
            
            let daysToAdd = i
            let calculatedDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: -daysToAdd, toDate: now, options: NSCalendarOptions.init(rawValue: 0))
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let newDates = dateFormatter.stringFromDate(calculatedDate!)
            crimedate = newDates
            loadDataFromSODAApi()
            i = i+1
            
            
        }
        
        
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[CLLocation]){
        
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude:location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let now = NSDate()
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: -1, toDate: now, options: NSCalendarOptions.init(rawValue: 0))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let newDates = dateFormatter.stringFromDate(calculatedDate!)
        crimedate = newDates
        
        centerMapOnLocation(startLocation)
        checkLocationAuthorizationStatus()
        mapView.delegate = self
        
        loadDataFromSODAApi()
        setUpNavigationBar()
        mapView.showsUserLocation = true
        
        
        
        
    }
    
    func mapView(mapView:MKMapView, didUpdateUserLocation userLocation:MKUserLocation){
        mapView.centerCoordinate = userLocation.location!.coordinate
    }

    func checkLocationAuthorizationStatus(){
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse{
            mapView.showsUserLocation = true
        } else{
            locationManager.requestWhenInUseAuthorization()
        }
        
        
    }
    
    func centerMapOnLocation(location:CLLocation){
        let coordinateRegion:MKCoordinateRegion! = MKCoordinateRegionMakeWithDistance(location.coordinate, initialRadius * 2.0, initialRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func setUpNavigationBar(){
        self.navigtionBar.barTintColor = UIColor.orangeColor()
        self.navigtionBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.blueColor()]
    }
    
    
    func loadDataFromSODAApi(){
        let session:NSURLSession! = NSURLSession.sharedSession()
        let url:NSURL! = NSURL(string: "https://data.illinois.gov/resource/ctfx-e3rj.json?occurred_on_date=\(crimedate)")
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error in
            guard let actualData = data else{
                return
            }
            do{
                let jsonResult:NSArray = try NSJSONSerialization.JSONObjectWithData(actualData, options: NSJSONReadingOptions.MutableLeaves) as! NSArray
                //  print("Number of Json Results loaded  = \(jsonResult.count)")
                dispatch_async(dispatch_get_main_queue(), {
                    for item in jsonResult {
                        let dataDictionary = item as! NSDictionary
                        let datapoint:DataPoints! = DataPoints.fromDataArray(dataDictionary)
                        self.dataPoints.append(datapoint)
                        var thepoint = MKPointAnnotation()
                        thepoint = MKPointAnnotation()
                        thepoint.coordinate = datapoint.coordinate
                        thepoint.title = datapoint.title
                        thepoint.subtitle = datapoint.district
                        self.mapView.addAnnotation(thepoint)
                    }
                })
                
            }catch let parseError{
                print("Response Status - \(parseError)")
            }
        })
        task.resume()
    }



}

