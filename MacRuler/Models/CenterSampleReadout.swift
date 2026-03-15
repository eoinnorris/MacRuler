//
//  CenterSampleReadout.swift
//  MacRuler
//
//  Created by OpenAI on 2026-02-23.
//

import CoreGraphics
import Foundation

struct CenterSampleReadout: Equatable {
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

    var normalizedRGB: (red: Double, green: Double, blue: Double) {
        (
            normalizedComponent(red),
            normalizedComponent(green),
            normalizedComponent(blue)
        )
    }

    var normalizedRGBLabel: String {
        let rgb = normalizedRGB
        return String(
            format: "RGB(%.3f, %.3f, %.3f)",
            locale: Locale(identifier: "en_US_POSIX"),
            rgb.red,
            rgb.green,
            rgb.blue
        )
    }

    var hsl: (hue: Int, saturation: Int, lightness: Int) {
        let normalized = normalizedRGB
        let maximum = max(normalized.red, normalized.green, normalized.blue)
        let minimum = min(normalized.red, normalized.green, normalized.blue)
        let delta = maximum - minimum
        let lightness = (maximum + minimum) / 2

        guard delta > 0 else {
            return (hue: 0, saturation: 0, lightness: percentage(lightness))
        }

        let saturation = delta / (1 - abs((2 * lightness) - 1))
        let huePrime: Double

        if maximum == normalized.red {
            huePrime = ((normalized.green - normalized.blue) / delta)
                .truncatingRemainder(dividingBy: 6)
        } else if maximum == normalized.green {
            huePrime = ((normalized.blue - normalized.red) / delta) + 2
        } else {
            huePrime = ((normalized.red - normalized.green) / delta) + 4
        }

        let hueDegrees = Int(round((huePrime * 60).truncatingRemainder(dividingBy: 360)))
        let normalizedHue = (hueDegrees + 360) % 360
        return (
            hue: normalizedHue,
            saturation: percentage(saturation),
            lightness: percentage(lightness)
        )
    }

    var hslLabel: String {
        let hsl = hsl
        return "HSL(\(hsl.hue), \(hsl.saturation)%, \(hsl.lightness)%)"
    }

    var coordinateLabel: String {
        "(\(pixelX), \(pixelY))"
    }

    func convertedCoordinateLabel(
        unitType: UnitTypes,
        measurementScale: Double,
        sourceScreenScale: Double
    ) -> String? {
        guard unitType != .pixels else {
            return nil
        }

        let safeSourceScale = max(sourceScreenScale, 0.1)
        let xPoints = CGFloat(pixelX) / safeSourceScale
        let yPoints = CGFloat(pixelY) / safeSourceScale

        let convertedX = unitType.formattedDistance(points: xPoints, screenScale: measurementScale)
        let convertedY = unitType.formattedDistance(points: yPoints, screenScale: measurementScale)
        return "(\(convertedX), \(convertedY))"
    }

    static func make(
        frameImage: CGImage,
        viewportSize: CGSize,
        contentFrame: CGRect,
        magnification: Double,
        screenScale: Double
    ) -> CenterSampleReadout? {
        let scaleModel = MagnifierPixelScaleModel(
            magnification: magnification,
            sourceScreenScale: screenScale
        )
        let viewCenter = CGPoint(x: viewportSize.width / 2, y: viewportSize.height / 2)
        let imageCenterPoint = CGPoint(
            x: viewCenter.x - contentFrame.minX,
            y: viewCenter.y - contentFrame.minY
        )

        let pixelX = scaleModel.sourcePixelIndex(forViewCoordinate: imageCenterPoint.x)
        let pixelY = scaleModel.sourcePixelIndex(forViewCoordinate: imageCenterPoint.y)

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

private func normalizedComponent(_ value: Int) -> Double {
    Double(min(max(value, 0), 255)) / 255.0
}

private func percentage(_ value: Double) -> Int {
    Int(round(min(max(value, 0), 1) * 100))
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
