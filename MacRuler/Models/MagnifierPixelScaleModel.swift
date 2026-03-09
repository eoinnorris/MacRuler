import CoreGraphics

struct MagnifierPixelScaleModel {
    let magnification: CGFloat
    let sourceScreenScale: CGFloat

    init(magnification: Double, sourceScreenScale: Double) {
        self.magnification = CGFloat(max(magnification, 0.1))
        self.sourceScreenScale = CGFloat(max(sourceScreenScale, 0.1))
    }

    var viewPointsPerSourcePixel: CGFloat {
        magnification / sourceScreenScale
    }

    func sourcePixelDistance(forViewDistance viewDistance: CGFloat) -> CGFloat {
        viewDistance * sourceScreenScale / magnification
    }

    func sourcePixelIndex(forViewCoordinate viewCoordinate: CGFloat) -> Int {
        Int((viewCoordinate * sourceScreenScale / magnification).rounded(.down))
    }
}
