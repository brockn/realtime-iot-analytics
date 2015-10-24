//
//  ViewController.swift
//  Test1
//
import UIKit
import CoreMotion

class ViewController: UIViewController {
    let FLUME_ENDPOINT = "http://ec2-52-24-241-251.us-west-2.compute.amazonaws.com:5140"
    let PHP_ENDPOINT = "http://ec2-52-24-241-251.us-west-2.compute.amazonaws.com:80"

    let manager = CMMotionManager()
    let queue = NSOperationQueue()
    var maxXValue = 0.0
    var maxYValue = 0.0
    var maxZValue = 0.0
    var endpointUrl = ""
    @IBOutlet weak var maxXTextBox: UITextField!
    @IBOutlet weak var maxYTextBox: UITextField!
    @IBOutlet weak var maxZTextBox: UITextField!
    @IBOutlet weak var endPoint: UISwitch!
    

    @IBAction func endPointSwitch(sender: AnyObject) {
        if endpointUrl == FLUME_ENDPOINT {
            endpointUrl = PHP_ENDPOINT
        } else {
            endpointUrl = FLUME_ENDPOINT
        }
        print("switched to ", endpointUrl)
    }

    @IBAction func reset(sender: AnyObject) {
        self.maxXValue = 0.0;
        self.maxYValue = 0.0;
        self.maxZValue = 0.0;
        dispatch_async(dispatch_get_main_queue()) {
            self.maxXTextBox.text = String(self.maxXValue)
            self.maxYTextBox.text = String(self.maxYValue)
            self.maxZTextBox.text = String(self.maxZValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        endpointUrl = FLUME_ENDPOINT
        if manager.deviceMotionAvailable {
            self.maxXTextBox.text = String(round(self.maxXValue*100)/100)
            self.maxYTextBox.text = String(round(self.maxYValue*100)/100)
            self.maxZTextBox.text = String(round(self.maxZValue*100)/100)
            manager.deviceMotionUpdateInterval = 0.02
            manager.startDeviceMotionUpdatesToQueue(queue) {
                [weak self] data, error in
                if data != nil {
                    let x = round(fabs((data?.userAcceleration.x)!)*100)/100
                    let y = round(fabs((data?.userAcceleration.y)!)*100)/100
                    let z = round(fabs((data?.userAcceleration.z)!)*100)/100
                    if x > self!.maxXValue {
                        self!.maxXValue = x;
                        dispatch_async(dispatch_get_main_queue()) {
                            self!.maxXTextBox.text = String(self!.maxXValue)
                        }
                        self!.sendEvent(x, y: y, z: z)
                    }
                    if y > self!.maxYValue {
                        self!.maxYValue = y;
                        dispatch_async(dispatch_get_main_queue()) {
                            self!.maxYTextBox.text = String(self!.maxYValue)
                        }
                        self!.sendEvent(x, y: y, z: z)
                    }
                    if z > self!.maxZValue {
                        self!.maxZValue = z;
                        dispatch_async(dispatch_get_main_queue()) {
                            self!.maxZTextBox.text = String(self!.maxZValue)
                        }
                        self!.sendEvent(x, y: y, z: z)
                    }
                }
            }
        } else {
            self.maxXTextBox.text = "NaN"
            self.maxYTextBox.text = "NaN"
            self.maxZTextBox.text = "NaN"
        }
    }
    func sendEvent(var x: Double, y: Double, z: Double) {
        // generate some bad data
        if arc4random() % 5 == 0 {
            x *= -1;
        }
        let params = ["x": x, "y": y, "z": z] as Dictionary<String, Double>
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted)
            let body = (String(data: data, encoding: NSUTF8StringEncoding)!)
            post(["body": body], url:endpointUrl)
        } catch let error as NSError {
            print(error)
        }
    }

    func post(params : Dictionary<String, String>, url : String) {
        do {
            let request = NSMutableURLRequest(URL: NSURL(string: url)!)
            let session = NSURLSession.sharedSession()
            request.HTTPMethod = "POST"
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject([params], options: NSJSONWritingOptions.PrettyPrinted)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            let task = session.dataTaskWithRequest(request, completionHandler:
                {data, response, error -> Void in
                    print("Response: \(response)")
            })
            task.resume()
        } catch let error as NSError {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

