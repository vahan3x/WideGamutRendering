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

    @IBOutlet private weak var topMetalView: MTKView!
    @IBOutlet private weak var bottomMetalView: MTKView!
    @IBOutlet private weak var imageView: UIImageView!

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
        bottomMetalView.colorPixelFormat = .bgra10_xr_srgb
        bottomMetalView.delegate = extendedRangeRenderer

        extendedRangeRenderer.setupWith(device: device, commandQueue: commandQueue)

        guard let redColor = CIColor(red: 1.0, green: 0.0, blue: 0.0, colorSpace: extendedRangeRenderer.displayP3ColorSpace) else {
            preconditionFailure("Couldn't creat a Core Image color with \(extendedRangeRenderer.displayP3ColorSpace) color space.")
        }

        let screenSizeInPixels = CGSize(width: UIScreen.main.bounds.width * UIScreen.main.scale,
                                        height: UIScreen.main.bounds.height * UIScreen.main.scale)

        let ciImage = CIImage(color: redColor)
            .cropped(to: CGRect(origin: .zero, size: screenSizeInPixels))

        extendedRangeRenderer.image = ciImage
        imageView.image = UIImage(ciImage: ciImage)

        topMetalView.setNeedsDisplay()
        bottomMetalView.setNeedsDisplay()
    }

}

