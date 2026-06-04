import AppKit

enum BrandIcon {
    /// A monochrome "sunburst" glyph (the Claude mark) drawn as a template image,
    /// so it renders like every other menu-bar icon: single color, transparent
    /// background, auto-adapting to light/dark. Resolution-independent (redrawn
    /// per scale), so it stays crisp on Retina.
    static func sunburst(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            let c = CGPoint(x: size / 2, y: size / 2)
            let outer = size * 0.46
            let baseHalf = size * 0.052
            let spokes = 12
            NSColor.black.setFill()
            for i in 0..<spokes {
                let a = CGFloat(i) * (2 * .pi / CGFloat(spokes))
                let dir = CGPoint(x: cos(a), y: sin(a))
                let perp = CGPoint(x: -sin(a), y: cos(a))
                let tip = CGPoint(x: c.x + dir.x * outer, y: c.y + dir.y * outer)
                let b1 = CGPoint(x: c.x + perp.x * baseHalf, y: c.y + perp.y * baseHalf)
                let b2 = CGPoint(x: c.x - perp.x * baseHalf, y: c.y - perp.y * baseHalf)
                let path = NSBezierPath()
                path.move(to: b1)
                path.line(to: tip)
                path.line(to: b2)
                path.close()
                path.fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
