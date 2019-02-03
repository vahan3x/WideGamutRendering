//
//  CoreImageRenderer.swift
//  WideGamutRendering
//
//  Created by Vahan Babayan on 2/3/19.
//  Copyright © 2019 vahan3x. All rights reserved.
//

import CoreImage
import Metal
import MetalKit

class CoreImageRenderer: NSObject {

    // MARK: - Properties

    var image: CIImage?

    let extendedColorSpace: CGColorSpace = {
        guard let cs = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else {
            preconditionFailure("Couldn't create an extended linear SRGB color space.")
        }

        return cs
    }()
    let displayP3ColorSpace: CGColorSpace = {
        guard let cs = CGColorSpace(name: CGColorSpace.displayP3) else {
            preconditionFailure("Couldn't create a Display P3 color space.")
        }

        return cs
    }()

    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var context: CIContext?

    // MARK: - Methods

    func setupWith(device: MTLDevice, commandQueue: MTLCommandQueue? = nil) {
        self.device = device
        guard let commandQueue = commandQueue ?? device.makeCommandQueue() else {
            preconditionFailure("Couldn't make a Metal command queue.")
        }
        self.commandQueue = commandQueue

        let context = CIContext(mtlDevice: device, options: [.workingFormat: CIFormat.RGBAh,
                                                             .workingColorSpace: displayP3ColorSpace,
                                                             .outputColorSpace: extendedColorSpace])
        self.context = context
    }
}

private typealias MetalViewDelegate = CoreImageRenderer
extension MetalViewDelegate: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func draw(in view: MTKView) {
        guard let context = context,
            let commandQueue = commandQueue,
            let image = image else { return }

        guard let commandBuffer = commandQueue.makeCommandBuffer(), let drawable = view.currentDrawable else { return }

        let destination = CIRenderDestination(width: Int(view.drawableSize.width), height: Int(view.drawableSize.height), pixelFormat: .rgba16Float, commandBuffer: commandBuffer) { () -> MTLTexture in
            return drawable.texture
        }
        destination.colorSpace = extendedColorSpace

        do {
            try context.startTask(toRender: image, to: destination)
        } catch {
            print("Couldn't render to a CIRenderDestination.")
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
