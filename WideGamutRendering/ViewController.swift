//
//  ViewController.swift
//  WideGamutRendering
//
//  Created by Vahan Babayan on 2/3/19.
//  Copyright © 2019 vahan3x. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    // MARK: - Properties

    private lazy var colorImage: CIImage = {
        guard let redColor = CIColor(red: 1.0, green: 0.0, blue: 0.0, colorSpace: extendedRangeRenderer.displayP3ColorSpace) else {
            preconditionFailure("Couldn't creat a Core Image color with \(extendedRangeRenderer.displayP3ColorSpace) color space.")
        }

        let screenSizeInPixels = CGSize(width: UIScreen.main.bounds.width * UIScreen.main.scale,
                                        height: UIScreen.main.bounds.height * UIScreen.main.scale)

        return CIImage(color: redColor)
            .cropped(to: CGRect(origin: .zero, size: screenSizeInPixels))
    }()

    private lazy var image: CIImage = {
        guard let url = Bundle.main.url(forResource: "Iceland-P3", withExtension: "jpg") else {
            preconditionFailure("Couldn't locate the Display P3 image in the bundle.")
        }
        guard let ciImage = CIImage(contentsOf: url) else {
            preconditionFailure("Couldn't create a Core Image image from the Display P3 image data.")
        }

        return ciImage
    }()

    // MARK: Outlets

    @IBOutlet private weak var topMetalView: MTKView!
    @IBOutlet private weak var bottomMetalView: MTKView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageSelectorControl: UISegmentedControl!

    @IBOutlet private var extendedRangeRenderer: CoreImageRenderer!

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
                preconditionFailure("Couldn't instantiate the metal rendering pipeline.")
        }

        topMetalView.device = device
        topMetalView.colorPixelFormat = .rgba16Float
        topMetalView.delegate = extendedRangeRenderer

        bottomMetalView.device = device
        bottomMetalView.colorPixelFormat = .bgra10_xr
        bottomMetalView.delegate = extendedRangeRenderer

        extendedRangeRenderer.setupWith(device: device, commandQueue: commandQueue)

        imageSelectorControlAction(imageSelectorControl)
    }

    // MARK: Actions

    @IBAction func imageSelectorControlAction(_ sender: UISegmentedControl) {
        var image: CIImage!
        switch sender.selectedSegmentIndex {
        case 0: image = colorImage
        case 1: image = self.image
        default:
            preconditionFailure("Unhandled segment selected")
        }

        extendedRangeRenderer.image = image
        imageView.image = UIImage(ciImage: image)

        topMetalView.setNeedsDisplay()
        bottomMetalView.setNeedsDisplay()
    }

}

