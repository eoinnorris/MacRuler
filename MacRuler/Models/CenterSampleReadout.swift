//
//  CenterSampleReadout.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-23.
//

import CoreGraphics

struct CenterSampleReadout {
    let pixelX: Int
    let pixelY: Int
    let red: Int
    let green: Int
    let blue: Int

    var hexValue: String {
        "#\(hexComponent(red))\(hexComponent(green))\(hexComponent(blue))"
    }

    var rgbLabel: String {
        "RGB(\(red), \(green), \(blue))"
    }

    var coordinateLabel: String {
        "(\(pixelX), \(pixelY))"
    }

    static func make(
        frameImage: CGImage,
        viewportSize: CGSize,
        contentFrame: CGRect,
        magnification: Double,
        screenScale: Double
    ) -> CenterSampleReadout? {
        let viewCenter = CGPoint(x: viewportSize.width / 2, y: viewportSize.height / 2)
        let imageCenterPoint = CGPoint(
            x: viewCenter.x - contentFrame.minX,
            y: viewCenter.y - contentFrame.minY
        )

        let safeMagnification = max(magnification, 0.1)
        let safeScale = max(screenScale, 0.1)

        let pixelX = Int((imageCenterPoint.x * safeScale / safeMagnification).rounded(.down))
        let pixelY = Int((imageCenterPoint.y * safeScale / safeMagnification).rounded(.down))

        let boundedX = min(max(pixelX, 0), frameImage.width - 1)
        let boundedY = min(max(pixelY, 0), frameImage.height - 1)

        guard let sampledColor = frameImage.sampledRGB(x: boundedX, y: boundedY) else {
            return nil
        }

        return CenterSampleReadout(
            pixelX: boundedX,
            pixelY: boundedY,
            red: sampledColor.red,
            green: sampledColor.green,
            blue: sampledColor.blue
        )
    }
}

private func hexComponent(_ value: Int) -> String {
    let clamped = min(max(value, 0), 255)
    return String(clamped, radix: 16, uppercase: true).leftPadding(toLength: 2, withPad: "0")
}

private extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        guard count < toLength else { return self }
        return String(repeating: String(character), count: toLength - count) + self
    }
}

private extension CGImage {
    func sampledRGB(x: Int, y: Int) -> (red: Int, green: Int, blue: Int)? {
        guard
            x >= 0,
            y >= 0,
            x < width,
            y < height,
            let dataProvider,
            let data = dataProvider.data,
            let bytes = CFDataGetBytePtr(data)
        else {
            return nil
        }

        let bitsPerPixel = max(self.bitsPerPixel, 32)
        let bytesPerPixel = bitsPerPixel / 8
        let offset = y * bytesPerRow + x * bytesPerPixel

        guard offset + 3 < CFDataGetLength(data) else {
            return nil
        }

        switch bitmapInfo.byteOrder {
        case .order32Little:
            return (
                red: Int(bytes[offset + 2]),
                green: Int(bytes[offset + 1]),
                blue: Int(bytes[offset])
            )
        default:
            return (
                red: Int(bytes[offset]),
                green: Int(bytes[offset + 1]),
                blue: Int(bytes[offset + 2])
            )
        }
    }
}
