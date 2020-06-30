//
//  PrespectiveTransformViewController.swift
//  CoreImageFilters
//
//  Created by Onur Işık on 29.06.2020.
//  Copyright © 2020 Onur Işık. All rights reserved.
//

import UIKit

class PrespectiveTransformViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var skewButton: UIButton!
    @IBOutlet weak var bumpButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var directionStack: UIStackView!
    
    @IBOutlet weak var topBottomButton: UIButton!
    @IBOutlet weak var leftRightButton: UIButton!
    
    @IBOutlet weak var degreeCollectionView: UICollectionView!
    @IBOutlet weak var tickValueLabel: UILabel!
    @IBOutlet weak var centerTickView: UIView!
    private let maximumValueLimit: Int = 30
    private var limitList: [Int] = []
    private let CellIdentifier = "CellIdentifier"
    private var visibleRect: CGRect = .zero
    private var cellWidth: CGFloat = 0
    private let cellHeight: CGFloat = 30
    private var oldIndexPath = IndexPath(item: 0, section: 0)
    private let generator = UISelectionFeedbackGenerator()
    private var currentValue: CGFloat = 0
    private var circleShape = CAShapeLayer()
    private var circleShapeTrackLayer = CAShapeLayer()
    
    var context: CIContext?
    var perspectiveTransformFilter: CIFilter?
    var orignalImage: UIImage = UIImage(named: "test_16")!
    private var imageCenterForDraw: CIVector = .init(cgPoint: .zero)
    private var imageCenterForFilter: CIVector = .init(cgPoint: .zero)
    
    private var width: CGFloat = 0
    private var height: CGFloat = 0
    private var smallRadius: CGFloat = 0
    private var intensityOfBump: CGFloat = 0
    
    private var viewLayedOut: Bool = false
    
    public enum Direction: String {
        case TopBottom, LeftRight
    }
    var choosedDirection:  Direction = .TopBottom
    
    public enum Feature: String {
        case Skew, Bump, Rotate
    }
    
    var currentFeature: Feature! {
        didSet {
            self.setState(currentFeature)
        }
    }
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        return tapGestureRecognizer
    }()
    
    private lazy var pichGesture: UIPinchGestureRecognizer = {
        let pichGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        return pichGestureRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        context = getGraphicsContext()
        perspectiveTransformFilter = getFilter()
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        imageView.addGestureRecognizer(pichGesture)
        
        guard let ciImage = CIImage(image: self.orignalImage) else {
            print("Cannot create ciImage from original image!")
            return
        }
        
        width = ciImage.extent.width
        height = ciImage.extent.height
        
        imageCenterForDraw = CIVector(x: width / 2,
                                      y: width / 2)
        
        imageCenterForFilter = imageCenterForDraw
        
        smallRadius = min(width / 4.0, height / 4.0)
        
        currentFeature = .Skew
        
        
        degreeCollectionView.delegate = self
        degreeCollectionView.dataSource = self
        degreeCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        limitList = Array<Int>(-maximumValueLimit...maximumValueLimit)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if viewLayedOut == false {
            
            tickValueLabel.backgroundColor = degreeCollectionView.backgroundColor
            tickValueLabel.layer.cornerRadius = tickValueLabel.bounds.width / 2
            tickValueLabel.layer.masksToBounds = true
            centerTickView.layer.cornerRadius = centerTickView.bounds.width / 2
            centerTickView.layer.masksToBounds = true
            
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: tickValueLabel.bounds.width / 2,
                                                             y: tickValueLabel.bounds.width / 2),
                                          radius: (tickValueLabel.bounds.width / 2) - 1,
                                          startAngle: -.pi/2, endAngle: CGFloat.pi * 2, clockwise: true)
        
            circleShapeTrackLayer.frame = tickValueLabel.bounds
            circleShapeTrackLayer.path = circlePath.cgPath
            circleShapeTrackLayer.strokeColor = UIColor(red: 110/255, green: 110/255, blue: 110/255, alpha: 1).cgColor
            circleShapeTrackLayer.fillColor = UIColor.clear.cgColor
            circleShapeTrackLayer.lineWidth = 2
            circleShapeTrackLayer.strokeEnd = 1.0
            tickValueLabel.layer.addSublayer(circleShapeTrackLayer)
            
            circleShape.frame = tickValueLabel.bounds
            circleShape.path = circlePath.cgPath
            circleShape.strokeColor = UIColor.white.cgColor
            circleShape.fillColor = UIColor.clear.cgColor
            circleShape.lineWidth = 2
            circleShape.lineCap = .round
            // set start and end values
            circleShape.strokeEnd = 0.0
            tickValueLabel.layer.addSublayer(circleShape)
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.repeatCount = 0
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            circleShape.add(animation, forKey: "strokeEndAnimation")
            
            viewLayedOut = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        degreeCollectionView.reloadData()
        self.degreeCollectionView.performBatchUpdates(nil, completion: { (result) in
            self.scrollToFeature()
        })
        
        print("Layer frame: \(circleShape.frame) and layer position: \(circleShape.position)")
    }
    
    private func scrollToFeature() {
        guard let itemIndex = limitList.firstIndex(of: 0) else { return }
        let destinationIndexPath = IndexPath(item: itemIndex, section: 0)
        degreeCollectionView.scrollToItem(at: destinationIndexPath, at: .centeredHorizontally, animated: true)
    }
    
    func snapToNearestCell(scrollView: UIScrollView) {
         let middlePoint = self.view.convert(self.degreeCollectionView.center, to: self.degreeCollectionView)
         if let indexPath = self.degreeCollectionView.indexPathForItem(at: middlePoint) {
            self.degreeCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
         }
    }
    
    private func getGraphicsContext() -> CIContext? {
        let openGLContext = EAGLContext(api: .openGLES3)
        return CIContext(eaglContext: openGLContext!)
    }
    
    private func getFilter() -> CIFilter? {
        let filter = CIFilter(name: "CIPerspectiveTransform")
        let coreImage = getCoreImage()
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        return filter
    }
    
    private func getCoreImage() -> CIImage? {
        return CIImage(image: self.orignalImage)
    }
    
    private func setState(_ feature: Feature) {
        if feature == .Skew {
            skewButton.isSelected = true
            bumpButton.isSelected = false
            rotateButton.isSelected = false
            directionStack.isHidden = false
            
            topBottomButton.isSelected = true
            imageView.isUserInteractionEnabled = false
        } else if feature == .Bump {
            skewButton.isSelected = false
            bumpButton.isSelected = true
            rotateButton.isSelected = false
            directionStack.isHidden = true
            
            imageView.isUserInteractionEnabled = true
        } else {
            skewButton.isSelected = false
            bumpButton.isSelected = false
            rotateButton.isSelected = true
            directionStack.isHidden = true
            
            imageView.isUserInteractionEnabled = false
        }
    }
    
    func applyperspectiveTransformWith(direction: Direction, value: CGFloat) -> UIImage {
        
        let positeValue = abs(value) * 2
        let size = orignalImage.size
        var topLeft = CIVector(x: 0, y: 0)
        var topRight = CIVector(x: size.width, y: 0)
        var bottomLeft = CIVector(x: 0, y: size.height)
        var bottomRight = CIVector(x: size.width, y: size.height)
                
        switch direction {
        case .TopBottom:
            if value < 0 {
                topLeft = CIVector(x: topLeft.x - positeValue, y: topLeft.y - positeValue)
                topRight = CIVector(x: topRight.x + positeValue, y: topRight.y - positeValue)
                bottomLeft = CIVector(x: bottomLeft.x + positeValue, y: bottomLeft.y - positeValue)
                bottomRight = CIVector(x: bottomRight.x - positeValue, y: bottomRight.y - positeValue)
            } else if value > 0 {
                topLeft = CIVector(x: topLeft.x + positeValue, y: topLeft.y + positeValue)
                topRight = CIVector(x: topRight.x - positeValue, y: topRight.y + positeValue)
                bottomLeft = CIVector(x: bottomLeft.x - positeValue, y: bottomLeft.y + positeValue)
                bottomRight = CIVector(x: bottomRight.x + positeValue, y: bottomRight.y + positeValue)
            } else { break }
        case .LeftRight:
            if value < 0 {
                topRight = CIVector(x: topRight.x + positeValue, y: topRight.y + positeValue)
                bottomRight = CIVector(x: bottomRight.x + positeValue, y: bottomRight.y - positeValue)
                topLeft = CIVector(x: topLeft.x + positeValue, y: topLeft.y - positeValue)
                bottomLeft = CIVector(x: bottomLeft.x + positeValue, y: bottomLeft.y + positeValue)
            } else if value > 0 {
                topLeft = CIVector(x: topLeft.x + positeValue, y: topLeft.y + positeValue)
                bottomLeft = CIVector(x: bottomLeft.x + positeValue, y: bottomLeft.y - positeValue)
                topRight = CIVector(x: topRight.x + positeValue, y: topRight.y - positeValue)
                bottomRight = CIVector(x: bottomRight.x + positeValue, y: bottomRight.y + positeValue)
            } else { break }
        }
        
        perspectiveTransformFilter?.setValue(topLeft,forKey: "inputTopLeft")
        perspectiveTransformFilter?.setValue(topRight,forKey: "inputTopRight")
        perspectiveTransformFilter?.setValue(bottomRight,forKey: "inputBottomRight")
        perspectiveTransformFilter?.setValue(bottomLeft,forKey: "inputBottomLeft")
        
        guard let outputImage = perspectiveTransformFilter?.outputImage else {
            print("Cannot get 'outputImage' from filter!")
            return self.orignalImage
        }

        guard let cgImage = context?.createCGImage(outputImage, from: outputImage.extent) else {
            print("Cannot convert 'outputImage' to core graphic image!")
            return self.orignalImage
        }

        return UIImage(cgImage: cgImage, scale: orignalImage.scale, orientation: .downMirrored)
    }
    
    func applyBumpDistort( radius : CGFloat, intensity: CGFloat) -> UIImage? {
        let currentFilter = CIFilter(name: "CIBumpDistortion")
        let beginImage = CIImage(image: self.orignalImage)
        currentFilter?.setValue(beginImage, forKey: kCIInputImageKey)


        currentFilter?.setValue(radius, forKey: kCIInputRadiusKey)
        currentFilter?.setValue(intensity, forKey: kCIInputScaleKey)
        currentFilter?.setValue(imageCenterForFilter, forKey: kCIInputCenterKey)

        guard let image = currentFilter?.outputImage else { return nil }

        if let cgimg = context?.createCGImage(image, from: image.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            return processedImage
        }
        return nil
    }
    
    func rotateImage(angle:CGFloat, flipVertical:CGFloat, flipHorizontal:CGFloat) -> UIImage? {
       let ciImage = CIImage(image: self.orignalImage)
           
       let filter = CIFilter(name: "CIAffineTransform")
       filter?.setValue(ciImage, forKey: kCIInputImageKey)
       filter?.setDefaults()
           
       let newAngle = angle * CGFloat(-1)
           
       var transform = CATransform3DIdentity
       transform = CATransform3DRotate(transform, CGFloat(newAngle), 0, 0, 1)
        transform = CATransform3DRotate(transform, CGFloat(Double(flipVertical) * .pi), 0, 1, 0)
        transform = CATransform3DRotate(transform, CGFloat(Double(flipHorizontal) * .pi), 1, 0, 0)
           
       let affineTransform = CATransform3DGetAffineTransform(transform)
           
       filter?.setValue(NSValue(cgAffineTransform: affineTransform), forKey: "inputTransform")
           
        let contex = CIContext(options: [CIContextOption.useSoftwareRenderer:true])
           
       let outputImage = filter?.outputImage
       let cgImage = contex.createCGImage(outputImage!, from: (outputImage?.extent)!)
           
       let result = UIImage(cgImage: cgImage!)
       return result
    }
    
    @IBAction func directionChoosed(_ sender: UIButton) {
        if sender.tag == 0 {
            choosedDirection = .TopBottom
            topBottomButton.isSelected = true
            leftRightButton.isSelected = false
        } else if sender.tag == 1 {
            choosedDirection = .LeftRight
            topBottomButton.isSelected = false
            leftRightButton.isSelected = true
        }
        
        circleShape.strokeEnd = 0.0
        
        /// Reset transform
        scrollToFeature()
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
                
        if currentFeature == .Bump {
            intensityOfBump = CGFloat(sender.value / 2)
            imageView.image = self.applyBumpDistort(radius: smallRadius, intensity: intensityOfBump)
        }
        
    }
    
    @IBAction func featureButtonPressed(_ sender: UIButton) {
        if sender.tag == 0 {
            currentFeature = .Skew
        } else if sender.tag == 1 {
            currentFeature = .Bump
        } else {
            currentFeature = .Rotate
        }
    }
    
    @objc
    private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
                
        let tappedPoint: CGPoint = gestureRecognizer.location(in: imageView)
        
        let realPoint = imageView.convertPoint(fromViewPoint: tappedPoint)
        self.imageCenterForFilter = CIVector(cgPoint: CGPoint(x: realPoint.x, y: self.orignalImage.size.height - realPoint.y))
        self.imageCenterForDraw = CIVector(cgPoint: CGPoint(x: realPoint.x, y: realPoint.y))
        
        let resultImage = self.applyBumpDistort(radius: smallRadius, intensity: intensityOfBump)
        drawBumpCircle(onImage: resultImage!, raidus: smallRadius)
                
    }

    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        
        let scale = gestureRecognizer.scale
                
        switch gestureRecognizer.state {
        case .began, .changed:
            
            smallRadius = (width / 4.0) * scale
            drawBumpCircle(onImage: orignalImage, raidus: smallRadius)
            
        case .ended, .cancelled:
            
            gestureRecognizer.scale = 1.0
            
            let resultImage = self.applyBumpDistort(radius: smallRadius, intensity: intensityOfBump)
            drawBumpCircle(onImage: resultImage!, raidus: smallRadius)
        default: break
        }
    }
    
    private func drawBumpCircle(onImage: UIImage, raidus: CGFloat) {
        // create context with image size
        UIGraphicsBeginImageContext(orignalImage.size)
        let context = UIGraphicsGetCurrentContext()
        
        // draw current image to the context
        onImage.draw(in: CGRect(x: 0, y: 0, width: onImage.size.width, height: onImage.size.height))
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(2.0)
        
        let circleRect = CGRect(x: imageCenterForDraw.x - raidus / 2, y: imageCenterForDraw.y - raidus / 2, width: raidus, height: raidus)
        context?.addEllipse(in: circleRect)
        context?.strokePath()
        
        // draw current context to image view
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        //close context
        UIGraphicsEndImageContext()
    }
}

extension UIImageView {
    
    func convertPoint(fromViewPoint viewPoint: CGPoint) -> CGPoint {
        guard let imageSize = image?.size else { return CGPoint.zero }
        
        var imagePoint = viewPoint
        let viewSize = bounds.size
        
        let ratioX = viewSize.width / imageSize.width
        let ratioY = viewSize.height / imageSize.height
        
        switch contentMode {
        case .scaleAspectFit: fallthrough
        case .scaleAspectFill:
            var scale : CGFloat = 0
            
            if contentMode == .scaleAspectFit {
                scale = min(ratioX, ratioY)
            }
            else {
                scale = max(ratioX, ratioY)
            }
            
            // Remove the x or y margin added in FitMode
            imagePoint.x -= (viewSize.width  - imageSize.width  * scale) / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height * scale) / 2.0
            
            imagePoint.x /= scale;
            imagePoint.y /= scale;
            
        case .scaleToFill: fallthrough
        case .redraw:
            imagePoint.x /= ratioX
            imagePoint.y /= ratioY
        case .center:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .top:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
        case .bottom:
            imagePoint.x -= (viewSize.width - imageSize.width)  / 2.0
            imagePoint.y -= (viewSize.height - imageSize.height);
        case .left:
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .right:
            imagePoint.x -= (viewSize.width - imageSize.width);
            imagePoint.y -= (viewSize.height - imageSize.height) / 2.0
        case .topRight:
            imagePoint.x -= (viewSize.width - imageSize.width);
        case .bottomLeft:
            imagePoint.y -= (viewSize.height - imageSize.height);
        case .bottomRight:
            imagePoint.x -= (viewSize.width - imageSize.width)
            imagePoint.y -= (viewSize.height - imageSize.height)
        case.topLeft: fallthrough
        default:
            break
        }
        
        return imagePoint
    }
}

extension PrespectiveTransformViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return limitList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? TickCell else {
            fatalError("Cannot get cell as NumberCell!")
        }
        cell.degree = limitList[indexPath.item]
        cell.tickSize = (indexPath.item % 5 == 0) ? .Big : .Small
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: cellWidth * 15, bottom: 0, right: cellWidth * 15)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        cellWidth = self.view.bounds.width / CGFloat(maximumValueLimit)
        return .init(width: cellWidth, height: cellHeight)
    }
    
    // MARK: UIScrollView

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let center = self.view.convert(self.degreeCollectionView.center, to: self.degreeCollectionView)
        if let indexPath = degreeCollectionView.indexPathForItem(at: center) {
            if indexPath != oldIndexPath {
                guard let centeredCell = degreeCollectionView.cellForItem(at: indexPath) as? TickCell else { return }
                tickValueLabel.text = String(centeredCell.degree)
                currentValue = CGFloat(centeredCell.degree)
                circleShape.strokeEnd = min(max(abs(currentValue / 35), 0), 1)
                
                generator.selectionChanged()
                
                if currentFeature == .Skew {
                    UIView.transition(with: imageView, duration: 0.1, options: .transitionCrossDissolve, animations: {
                        self.imageView.image = self.applyperspectiveTransformWith(direction: self.choosedDirection, value: self.currentValue)
                    }) { (_) in }
                    
                } else if currentFeature == .Rotate {
                    let value = CGFloat((currentValue / 30) * .pi)
                    imageView.image = self.rotateImage(angle: value, flipVertical: 0, flipHorizontal: 0)
                }
                self.oldIndexPath = indexPath
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.snapToNearestCell(scrollView: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.snapToNearestCell(scrollView: scrollView)
    }
}
