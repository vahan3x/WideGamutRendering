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
        guard let cs = CGColorSpace(name: CGColorSpace.extendedSRGB) else {
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
                                                             .workingColorSpace: displayP3ColorSpace])
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

        let scale = max(view.drawableSize.width / image.extent.width,
                        view.drawableSize.height / image.extent.height)
        let tx = (view.drawableSize.width - scale * image.extent.width) / 2.0
        let ty = (view.drawableSize.height - scale * image.extent.height) / 2.0
        let t = CGAffineTransform(translationX: tx, y: ty).scaledBy(x: scale, y: scale)
        let scaledImage = image.applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey: t])

        guard let commandBuffer = commandQueue.makeCommandBuffer(), let drawable = view.currentDrawable else { return }

        if view.colorPixelFormat == .bgra10_xr || view.colorPixelFormat == .bgra10_xr_srgb { // This pixel formats are not supported by the CIRenderDestination
            context.render(scaledImage, to: drawable.texture, commandBuffer: commandBuffer, bounds: CGRect(origin: .zero, size: view.drawableSize), colorSpace: extendedColorSpace)
        } else {
            let destination = CIRenderDestination(width: Int(view.drawableSize.width), height: Int(view.drawableSize.height), pixelFormat: view.colorPixelFormat, commandBuffer: commandBuffer) { () -> MTLTexture in
                return drawable.texture
            }
            destination.colorSpace = extendedColorSpace

            do {
                try context.startTask(toRender: scaledImage, to: destination)
            } catch {
                print("Couldn't render to a CIRenderDestination.")
            }
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
