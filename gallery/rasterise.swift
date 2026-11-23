import AppKit
import PDFKit

let args = CommandLine.arguments
guard args.count == 5 || args.count == 9 else {
  print("usage: rasterise.swift PDF PAGE OUT.png WIDTH_PX [X Y W H in mm from the top left]")
  exit(1)
}
let doc = PDFDocument(url: URL(fileURLWithPath: args[1]))!
let page = doc.page(at: Int(args[2])! - 1)!
let box = page.bounds(for: .mediaBox)
let mm = 72 / 25.4
var crop = box
if args.count == 9 {
  let v = args[5...8].map { CGFloat(Double($0)!) * mm }
  crop = CGRect(x: v[0], y: box.height - v[1] - v[3], width: v[2], height: v[3])
}
let scale = CGFloat(Double(args[4])!) / crop.width
let w = Int((crop.width * scale).rounded()), h = Int((crop.height * scale).rounded())
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
  hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
ctx.setFillColor(.white)
ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
ctx.scaleBy(x: scale, y: scale)
ctx.translateBy(x: -crop.minX, y: -crop.minY)
page.draw(with: .mediaBox, to: ctx)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[3]))
