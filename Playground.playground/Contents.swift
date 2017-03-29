//: Playground - noun: a place where people can play

import UIKit

class NCUnitFormatter: Formatter {
	enum Unit {
		case none
		case isk
		case skillPoints
		case gigaJoule
		case gigaJoulePerSecond
		case megaWatts
		case teraflops
		case kilogram
		case meter
		case millimeter
		case megaBitsPerSecond
		case cubicMeter
		case meterPerSecond
		case auPerSecond
		case custom(String, Bool)
		
		var useSIPrefix: Bool {
			switch self {
			case .isk, .skillPoints, .meter, .millimeter, .meterPerSecond, .auPerSecond:
				return false
			case .gigaJoule, .gigaJoulePerSecond, .megaWatts, .teraflops, .kilogram, .megaBitsPerSecond, .cubicMeter:
				return true
			case let .custom(_, bool):
				return bool
			default:
				return false
			}
		}
		
		var abbreviation: String {
			switch (self) {
			case .isk:
				return NSLocalizedString("ISK", comment: "isk")
			case .skillPoints:
				return NSLocalizedString("SP", comment: "skillPoints")
			case .gigaJoule:
				return NSLocalizedString("GJ", comment: "gigaJoule")
			case .gigaJoulePerSecond:
				return NSLocalizedString("GJ/s", comment: "gigaJoulePerSecond")
			case .megaWatts:
				return NSLocalizedString("MW", comment: "megaWatts")
			case .teraflops:
				return NSLocalizedString("tf", comment: "teraflops")
			case .kilogram:
				return NSLocalizedString("kg", comment: "kilogram")
			case .meter:
				return NSLocalizedString("m", comment: "meter")
			case .millimeter:
				return NSLocalizedString("mm", comment: "millimeter")
			case .megaBitsPerSecond:
				return NSLocalizedString("Mbit/s", comment: "megaBitsPerSecond")
			case .cubicMeter:
				return NSLocalizedString("m³", comment: "cubicMeter")
			case .meterPerSecond:
				return NSLocalizedString("m/s", comment: "meterPerSecond")
			case .auPerSecond:
				return NSLocalizedString("AU/s", comment: "auPerSecond")
			case let .custom(string, _):
				return string
				
			default:
				return ""
			}
		}
	}
	
	enum Style: Int {
		case short
		case full
	}
	
	let unit: Unit
	let style: Style
	let useSIPrefix: Bool?
	
	private static let numberFormatter1: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.positiveFormat = "#,##0.##"
		numberFormatter.groupingSeparator = " "
		numberFormatter.decimalSeparator = "."
		return numberFormatter
		
	}()
	
	private static let numberFormatter2: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.positiveFormat = "#,##0"
		numberFormatter.groupingSeparator = " "
		numberFormatter.decimalSeparator = "."
		return numberFormatter
		
	}()
	
	init(unit: Unit = .none, style: Style = .full, useSIPrefix: Bool? = nil) {
		self.unit = unit
		self.style = style
		self.useSIPrefix = useSIPrefix
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		//self.unit = Unit(rawValue: aDecoder.decodeInteger(forKey: "unit")) ?? .none
		self.unit = .none
		self.style = Style(rawValue: aDecoder.decodeInteger(forKey: "style")) ?? .full
		useSIPrefix = aDecoder.containsValue(forKey: "useSIPrefix") ? aDecoder.decodeBool(forKey: "useSIPrefix") : nil
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		//aCoder.encode(unit.rawValue, forKey: "unit")
		aCoder.encode(style.rawValue, forKey: "style")
		aCoder.encode(useSIPrefix, forKey: "useSIPrefix")
	}
	
	class func localizedString(from number: Int32, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}
	
	
	class func localizedString(from number: Int, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}
	
	class func localizedString(from number: Float, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		return localizedString(from: Double(number), unit: unit, style: style)
	}
	
	class func localizedString(from number: Double, unit: Unit, style: Style, useSIPrefix: Bool? = nil) -> String {
		let unitAbbreviation: String = unit.abbreviation
		let useSIPrefix = useSIPrefix ?? unit.useSIPrefix
		
		let sign = number < 0 ? -1.0 : 1.0
		var value = abs(number)
		var suffix: String
		if (style == .short) {
			if (value >= 10_000_000_000_000) {
				suffix = NSLocalizedString("T", comment: "trillion")
				value /= 1_000_000_000.0
			}
			else if (value >= 10_000_000_000) {
				if (useSIPrefix) {
					suffix = NSLocalizedString("G", comment: "billion")
				}
				else {
					suffix = NSLocalizedString("B", comment: "billion")
				}
				value /= 1_000_000_000.0
			}
			else if (value >= 10_000_000) {
				suffix = NSLocalizedString("M", comment:"million")
				value /= 1_000_000.0
			}
			else if (value >= 10_000) {
				suffix = NSLocalizedString("k", comment: "thousand")
				value /= 1000.0
			}
			else {
				suffix = ""
			}
		}
		else {
			suffix = ""
		}
		
		var s = ""
		if value < 10.0 {
			s = numberFormatter1.string(from: NSNumber(value: value * sign))!
		}
		else {
			s = numberFormatter2.string(from: NSNumber(value: value * sign))!
		}
		if !unitAbbreviation.isEmpty {
			suffix = " \(suffix)\(unitAbbreviation)"
		}
		s += suffix
		return s;
	}
	
	override func string(for obj: Any?) -> String? {
		switch obj {
		case let obj as Double:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: true)
		case let obj as Float:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: true)
		case let obj as Int:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: true)
		case let obj as Int32:
			return NCUnitFormatter.localizedString(from: obj, unit: unit, style: style, useSIPrefix: true)
		default:
			return nil
		}
	}
	
}


class ChartView: UIView {
	
	var grid: CGSize = CGSize(width: 24, height: 24)
	
	var xFormatter: Formatter = NCUnitFormatter(unit: .meter, style: .short, useSIPrefix: nil)
	var yFormatter: Formatter = NCUnitFormatter(unit: .none, style: .full, useSIPrefix: nil)
	var dimension: (x: Double, y: Double) = (37845, 500)
	
	private lazy var attributes: [String: Any] = {
		return [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote), NSForegroundColorAttributeName: UIColor.white]
	}()

	private var xCaptions: [(CGRect, NSAttributedString)] = []
	private var yCaptions: [(CGRect, NSAttributedString)] = []
	
	var canvas: CGRect {
		guard let x = xCaptions.first, let y = yCaptions.first else {return bounds}
		var canvas = bounds
		canvas.origin.x = x.0.maxX + 4
		canvas.size.width = trunc((bounds.size.width - canvas.origin.x) / grid.width) * grid.width
		canvas.size.height = trunc((bounds.size.height - y.0.size.height) / grid.height) * grid.height
		canvas.origin.y = y.0.minY - canvas.size.height
		return canvas
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		
		var s = NSAttributedString(string: "0", attributes:attributes)
		var zero = s.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
		
		var y = bounds.size.height - zero.size.height
		
		zero.origin.x = -zero.size.width
		zero.origin.y = y - zero.size.height / 2
		
		let h = bounds.size.height - zero.size.height
		
		var prev = zero
		
		y -= grid.height
		
		var xCaptions = [(CGRect, NSAttributedString)]()
		xCaptions.append((zero, s))
		
		var minX = zero.origin.x
		if dimension.y > 0 {
			while y > zero.size.height / 2 {
				
				s = NSAttributedString(string: yFormatter.string(for: Double((h - y) / h) * dimension.y)!, attributes: attributes)
				var rect = s.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
				rect.origin.x = -rect.size.width
				rect.origin.y = y - rect.size.height / 2
				if !prev.intersects(rect) {
					prev = rect
					xCaptions.append((rect, s))
					minX = min(rect.origin.x, minX)
				}
				y -= grid.height
			}
		}
		
		let transform = CGAffineTransform(translationX: -minX, y: 0)
		xCaptions = xCaptions.map { ($0.0.applying(transform), $0.1) }
		zero = zero.applying(transform)
		
		var yCaptions = [(CGRect, NSAttributedString)]()
		if dimension.x > 0 {
			zero.size.width += 4
			var x = zero.maxX + grid.width
			let w = bounds.size.width - zero.maxX
			prev = zero
			while x < bounds.size.width {
				s = NSAttributedString(string: xFormatter.string(for: Double(x / w) * dimension.x)!, attributes: attributes)
				var rect = s.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
				rect.origin.x = x - rect.size.width
				rect.origin.y = bounds.size.height - rect.size.height
				
				if rect.maxX > bounds.size.width {
					break
				}
				
				if !prev.intersects(rect) {
					prev = rect
					yCaptions.append((rect, s))
				}

				
				x += grid.width
			}
		}
		
		self.xCaptions = xCaptions
		self.yCaptions = yCaptions
	}
	
	override func draw(_ rect: CGRect) {
		UIColor.black.setFill()
		UIGraphicsGetCurrentContext()?.fill(rect)
		
		for s in xCaptions {
			s.1.draw(in: s.0)
		}
		for s in yCaptions {
			s.1.draw(in: s.0)
		}
		
		UIColor.lightGray.setStroke()
		let canvas = self.canvas
		
		let path = UIBezierPath()
		path.lineWidth = 1.0 / UIScreen.main.scale
		
		var p = CGPoint(x: canvas.minX, y: canvas.maxY)
		path.move(to: p)
		path.addLine(to: CGPoint(x: p.x, y: canvas.minY))
		while p.x < canvas.maxX {
			p.x += grid.width
			path.move(to: p)
			path.addLine(to: CGPoint(x: p.x, y: p.y - 4))
		}
		p = canvas.origin
		while p.y < canvas.maxY {
			path.move(to: p)
			path.addLine(to: CGPoint(x: p.x + 4, y: p.y))
			p.y += grid.height
		}
		path.move(to: p)
		path.addLine(to: CGPoint(x: canvas.maxX, y: p.y))
		path.stroke()
	}
}

let chart = ChartView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height:128)))
chart.backgroundColor = .black



chart

let font = UIFont.preferredFont(forTextStyle: .footnote)

font.lineHeight
font.xHeight
font.capHeight
font.ascender
font.descender
font.pointSize

font.ascender - font.descender

let p = NSMutableParagraphStyle()
print (p.description)
