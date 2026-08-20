import Cocoa
import WebKit
import Foundation
import CryptoKit

// Initialize Headless Cocoa App
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

// MARK: - CLI Argument Parser
struct Options {
    var inputFile: String?
    var outputDir: String = FileManager.default.currentDirectoryPath
    var prefix: String = "diagram"
    var theme: String = "simple"
    var title: String = "Sequence Diagram"
    var formats: Set<String> = ["pdf", "png"]
    var jsonOutput: Bool = true
}

func printHelp() {
    print("""
    Usage: sequify-cli [options] / swift render_diagram.swift [options]
    
    Options:
      -i, --input <file>        Input sequence diagram text file (reads stdin if omitted or '-')
      -d, --output-dir <dir>    Output directory (default: current working directory)
      -p, --prefix <name>       Output file prefix (default: 'diagram')
      -t, --theme <theme>       Theme: 'simple' or 'hand' (default: 'simple')
      --title <string>          Title for HTML document (default: 'Sequence Diagram')
      -f, --format <formats>    Comma-separated list: pdf,png,svg,html,all (default: 'pdf,png')
      --no-json                 Output plain text instead of JSON
      -h, --help                Show this help message
    """)
}

func parseArguments() -> Options {
    var options = Options()
    let args = ProcessInfo.processInfo.arguments
    var i = 1
    while i < args.count {
        let arg = args[i]
        switch arg {
        case "-i", "--input":
            if i + 1 < args.count {
                options.inputFile = args[i + 1]
                i += 1
            }
        case "-d", "--output-dir":
            if i + 1 < args.count {
                options.outputDir = args[i + 1]
                i += 1
            }
        case "-p", "--prefix":
            if i + 1 < args.count {
                options.prefix = args[i + 1]
                i += 1
            }
        case "-t", "--theme":
            if i + 1 < args.count {
                options.theme = args[i + 1]
                i += 1
            }
        case "--title":
            if i + 1 < args.count {
                options.title = args[i + 1]
                i += 1
            }
        case "-f", "--format":
            if i + 1 < args.count {
                let fmtList = args[i + 1].lowercased().split(separator: ",").map(String.init)
                if fmtList.contains("all") {
                    options.formats = ["pdf", "png", "svg", "html"]
                } else {
                    options.formats = Set(fmtList)
                }
                i += 1
            }
        case "--no-json":
            options.jsonOutput = false
        case "-h", "--help":
            printHelp()
            exit(0)
        default:
            if !arg.hasPrefix("-") && options.inputFile == nil {
                options.inputFile = arg
            }
        }
        i += 1
    }
    return options
}

let options = parseArguments()

// MARK: - Read Input Diagram Text
var diagramSource: String = ""
if let inputFile = options.inputFile, inputFile != "-" {
    let inputURL = URL(fileURLWithPath: inputFile)
    do {
        diagramSource = try String(contentsOf: inputURL, encoding: .utf8)
    } catch {
        fputs("Error: Unable to read input file at '\(inputFile)': \(error.localizedDescription)\n", stderr)
        exit(1)
    }
} else {
    let standardInput = FileHandle.standardInput
    let inputData = standardInput.readDataToEndOfFile()
    if let str = String(data: inputData, encoding: .utf8) {
        diagramSource = str
    }
}

if diagramSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
    fputs("Error: Sequence diagram input is empty.\n", stderr)
    exit(1)
}

// Input size boundary check (max 512 KB) to prevent resource exhaustion / DoS
let maxDiagramBytes = 512 * 1024
if diagramSource.utf8.count > maxDiagramBytes {
    fputs("Error: Sequence diagram input exceeds maximum allowed size (512 KB).\n", stderr)
    exit(1)
}

// MARK: - Cryptographic Vendor Integrity Hashes (SHA-256)
let expectedVendorHashes: [String: String] = [
    "ArchitectsDaughter-Regular.ttf": "6159718a08898e34bc1cb7354086141a5f9a70b73e54dbec27ead0d59a697359",
    "sequence-diagram-snap-min.js": "115a5a788eb973e7769a5473c6c9c9b7559f4159016745c229a9e3fae23cf7a8",
    "snap.svg-min.js": "86e81b5129457e636670017ed841b4ef3f85e3ee159fac9aea79da91335a4c5f",
    "svginnerhtml.min.js": "c83766ba7e847c2682223ae9cae26882b072c5ec5b7d99985e58c1122547f924",
    "underscore-min.js": "a1b6400a21ddee090e93d8882ffa629963132785bfa41b0abbea199d278121e9"
]

// MARK: - Locate Vendor Resources (Multi-Path Resolution with SHA-256 SRI)
func findVendorDirectory() -> URL {
    let fm = FileManager.default
    var candidateLocations: [URL] = []
    
    // 1. Relative to #filePath (the Swift source file location when run as script or compiled)
    let sourceFileURL = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
    candidateLocations.append(sourceFileURL.appendingPathComponent("../resources/vendor").standardized)
    
    // 2. Relative to CommandLine.arguments[0] (when run as script or binary)
    if let firstArg = CommandLine.arguments.first {
        let firstArgURL = URL(fileURLWithPath: firstArg).resolvingSymlinksInPath().deletingLastPathComponent()
        candidateLocations.append(firstArgURL.appendingPathComponent("../resources/vendor").standardized)
    }
    
    // 3. Relative to ProcessInfo executable path
    let execURL = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0]).resolvingSymlinksInPath().deletingLastPathComponent()
    candidateLocations.append(execURL.appendingPathComponent("../resources/vendor").standardized)
    
    // 4. Current working directory variants
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    candidateLocations.append(cwd.appendingPathComponent("resources/vendor").standardized)
    candidateLocations.append(cwd.appendingPathComponent("sequify/resources/vendor").standardized)
    candidateLocations.append(cwd.appendingPathComponent(".agents/skills/sequify/resources/vendor").standardized)
    candidateLocations.append(cwd.appendingPathComponent(".agents/skills/diagram/resources/vendor").standardized)
    
    // 5. Standard user config skill paths
    let home = fm.homeDirectoryForCurrentUser
    candidateLocations.append(home.appendingPathComponent(".gemini/config/skills/sequify/resources/vendor").standardized)
    candidateLocations.append(home.appendingPathComponent(".gemini/config/skills/diagram/resources/vendor").standardized)
    candidateLocations.append(home.appendingPathComponent(".agents/skills/sequify/resources/vendor").standardized)
    
    for candidate in candidateLocations {
        if fm.fileExists(atPath: candidate.appendingPathComponent("underscore-min.js").path) {
            return candidate
        }
    }
    
    fputs("Error: Could not locate vendor resources directory.\n", stderr)
    exit(1)
}

let vendorDir = findVendorDirectory()

func loadAndVerifyVendorData(_ filename: String) -> Data {
    guard let expectedHash = expectedVendorHashes[filename] else {
        fputs("Security Error: No integrity hash registered for vendor file '\(filename)'.\n", stderr)
        exit(1)
    }
    
    let fileURL = vendorDir.appendingPathComponent(filename)
    guard let data = try? Data(contentsOf: fileURL) else {
        fputs("Error: Unable to load vendor file at '\(fileURL.path)'.\n", stderr)
        exit(1)
    }
    
    let computedDigest = SHA256.hash(data: data)
    let computedHash = computedDigest.map { String(format: "%02x", $0) }.joined()
    
    if computedHash.lowercased() != expectedHash.lowercased() {
        fputs("Security Error: Cryptographic integrity check failed for vendor resource '\(filename)'.\nExpected SHA-256: \(expectedHash)\nFound SHA-256:    \(computedHash)\n", stderr)
        exit(1)
    }
    
    return data
}

func loadAndVerifyVendorString(_ filename: String) -> String {
    let data = loadAndVerifyVendorData(filename)
    guard let str = String(data: data, encoding: .utf8) else {
        fputs("Error: Vendor file '\(filename)' is not valid UTF-8.\n", stderr)
        exit(1)
    }
    return str
}

let snapJS = loadAndVerifyVendorString("snap.svg-min.js")
let underscoreJS = loadAndVerifyVendorString("underscore-min.js")
let sequenceJS = loadAndVerifyVendorString("sequence-diagram-snap-min.js")
let svgInnerJS = loadAndVerifyVendorString("svginnerhtml.min.js")

// Base64 encode Architects Daughter font for offline hand-drawn theme rendering
let fontData = loadAndVerifyVendorData("ArchitectsDaughter-Regular.ttf")
let b64 = fontData.base64EncodedString()
let embeddedFontCSS = """
@font-face {
    font-family: 'Architects Daughter';
    src: url('data:font/truetype;charset=utf-8;base64,\(b64)') format('truetype');
    font-weight: normal;
    font-style: normal;
}
@font-face {
    font-family: 'danielbd';
    src: url('data:font/truetype;charset=utf-8;base64,\(b64)') format('truetype');
    font-weight: normal;
    font-style: normal;
}
@font-face {
    font-family: 'daniel';
    src: url('data:font/truetype;charset=utf-8;base64,\(b64)') format('truetype');
    font-weight: normal;
    font-style: normal;
}
"""

// MARK: - HTML Builder
func buildHTML(diagramText: String, theme: String, title: String) -> String {
    // Sanitize title for safe HTML embedding
    let safeTitle = title
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
    
    // Safely JSON serialize diagram text to prevent script tag breakouts, XSS, or template injections
    let serializedDiagramJSON: String
    if let jsonData = try? JSONSerialization.data(withJSONObject: [diagramText], options: []),
       let jsonStr = String(data: jsonData, encoding: .utf8) {
        serializedDiagramJSON = jsonStr
    } else {
        serializedDiagramJSON = "[]"
    }
    
    let themeStyles: String
    if theme == "hand" {
        themeStyles = """
        .sequence {
            font-size: 16px;
        }
        .sequence .actor text,
        .sequence .signal text,
        .sequence .label text,
        .sequence .note text,
        .sequence .title text {
            fill: #000000;
            stroke: none;
            font-family: 'Architects Daughter', cursive !important;
        }
        """
    } else {
        themeStyles = """
        .sequence {
            font-size: 14px;
        }
        .signal text {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
            font-size: 13px !important;
        }
        .actor text {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
            font-weight: 600 !important;
            font-size: 13px !important;
        }
        .note text {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
            font-size: 12px !important;
        }
        .title text {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
            font-weight: 700 !important;
            font-size: 16px !important;
        }
        """
    }
    
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>\(safeTitle)</title>
    <style>
    \(embeddedFontCSS)
    * { box-sizing: border-box; }
    body {
        margin: 0;
        padding: 36px;
        background: #ffffff;
        font-family: \(theme == "hand" ? "'Architects Daughter', cursive" : "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif");
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
    }
    #diagram {
        display: inline-block;
        background: #ffffff;
    }
    svg {
        display: block;
        margin: 0 auto;
    }
    \(themeStyles)
    </style>
    <script>
    window.WebFont = {
        load: function(opts) {
            if (opts && typeof opts.active === 'function') opts.active();
        }
    };
    </script>
    <script>\(snapJS)</script>
    <script>\(underscoreJS)</script>
    <script>\(sequenceJS)</script>
    <script>\(svgInnerJS)</script>
    </head>
    <body>
    <div id="diagram"></div>
    <script>
    window.addEventListener("DOMContentLoaded", async function() {
        try {
            if (document.fonts) {
                await document.fonts.ready;
            }
            var payload = \(serializedDiagramJSON);
            var raw = (payload && payload.length > 0) ? payload[0] : "";
            var d = Diagram.parse(raw);
            var container = document.getElementById("diagram");
            d.drawSVG(container, { theme: '\(theme)' });
            
            var svg = container.querySelector("svg");
            if (svg) {
                var bbox = svg.getBBox();
                var width = Math.ceil(bbox.width + 40);
                var height = Math.ceil(bbox.height + 40);
                window.renderStatus = JSON.stringify({
                    status: "success",
                    theme: "\(theme)",
                    width: width,
                    height: height
                });
            } else {
                window.renderStatus = JSON.stringify({
                    status: "error",
                    message: "No SVG element generated"
                });
            }
        } catch (e) {
            window.renderStatus = JSON.stringify({
                status: "error",
                message: e.message || String(e)
            });
        }
    });
    </script>
    </body>
    </html>
    """
}

// MARK: - Exporter Class
class DiagramExporter: NSObject, WKNavigationDelegate {
    let options: Options
    let htmlContent: String
    var webView: WKWebView!
    
    init(options: Options, htmlContent: String) {
        self.options = options
        self.htmlContent = htmlContent
        super.init()
        
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1800, height: 2200), configuration: config)
        self.webView.navigationDelegate = self
    }
    
    func start() {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.checkReady(attempt: 0)
    }
    
    func checkReady(attempt: Int) {
        if attempt > 100 {
            fputs("Timeout waiting for diagram to render\n", stderr)
            exit(1)
        }
        self.webView.evaluateJavaScript("Boolean(document.querySelector('#diagram svg'))", completionHandler: { [weak self] (ready: Any?, _) in
            guard let self = self else { return }
            if let isReady = ready as? Bool, isReady {
                self.processDiagram()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    self.checkReady(attempt: attempt + 1)
                }
            }
        })
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fputs("Navigation error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    
    func processDiagram() {
        let js = """
        (() => {
            if (window.renderStatus && window.renderStatus.startsWith("error")) {
                return { error: window.renderStatus };
            }
            var container = document.getElementById("diagram");
            if (!container) return { error: "Container element not found" };
            var svg = container.querySelector("svg");
            if (!svg) return { error: "No SVG element generated inside diagram container." };
            
            var bbox = svg.getBBox();
            var svgW = (svg.width && svg.width.baseVal && svg.width.baseVal.value > 0) ? svg.width.baseVal.value : bbox.width;
            var svgH = (svg.height && svg.height.baseVal && svg.height.baseVal.value > 0) ? svg.height.baseVal.value : bbox.height;
            
            var margin = 72;
            var totalW = Math.ceil(svgW + margin);
            var totalH = Math.ceil(svgH + margin);
            
            var svgXML = '<?xml version="1.0" encoding="utf-8" standalone="no"?>\\n' +
                         '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">\\n' +
                         svg.outerHTML;
            
            return {
                width: totalW,
                height: totalH,
                svgContent: svgXML
            };
        })()
        """
        
        webView.evaluateJavaScript(js, completionHandler: { [weak self] (result: Any?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                fputs("JavaScript evaluation failed: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            
            guard let dict = result as? [String: Any] else {
                fputs("Unexpected result from browser engine\n", stderr)
                exit(1)
            }
            
            if let errMsg = dict["error"] as? String {
                fputs("\(errMsg)\n", stderr)
                exit(1)
            }
            
            let width = (dict["width"] as? Double) ?? 1000
            let height = (dict["height"] as? Double) ?? 800
            let svgContent = (dict["svgContent"] as? String) ?? ""
            
            // Prepare output paths
            let outputDirURL = URL(fileURLWithPath: self.options.outputDir)
            try? FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true, attributes: nil)
            
            let baseOutput = outputDirURL.appendingPathComponent(self.options.prefix)
            var generatedFiles: [String: String] = [:]
            
            // 1. Export HTML
            if self.options.formats.contains("html") {
                let htmlPath = baseOutput.appendingPathExtension("html").path
                do {
                    try self.htmlContent.write(toFile: htmlPath, atomically: true, encoding: .utf8)
                    generatedFiles["html"] = htmlPath
                } catch {
                    fputs("Warning: Failed to save HTML: \(error.localizedDescription)\n", stderr)
                }
            }
            
            // 2. Export SVG
            if self.options.formats.contains("svg") {
                let svgPath = baseOutput.appendingPathExtension("svg").path
                do {
                    try svgContent.write(toFile: svgPath, atomically: true, encoding: .utf8)
                    generatedFiles["svg"] = svgPath
                } catch {
                    fputs("Warning: Failed to save SVG: \(error.localizedDescription)\n", stderr)
                }
            }
            
            // Resize webView to fit content perfectly for snapshot and PDF
            self.webView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            
            // Wait brief tick for webView re-layout
            let exportWork = DispatchWorkItem {
                self.performMediaExports(baseOutput: baseOutput, width: width, height: height, generatedFiles: generatedFiles)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: exportWork)
        })
    }
    
    func performMediaExports(baseOutput: URL, width: Double, height: Double, generatedFiles: [String: String]) {
        var files = generatedFiles
        let group = DispatchGroup()
        
        // 3. Export PNG (High-DPI 2x)
        if options.formats.contains("png") {
            group.enter()
            let snapConfig = WKSnapshotConfiguration()
            snapConfig.snapshotWidth = NSNumber(value: width * 2.0)
            
            webView.takeSnapshot(with: snapConfig, completionHandler: { (image: NSImage?, error: Error?) in
                defer { group.leave() }
                if let error = error {
                    fputs("Warning: PNG snapshot failed: \(error.localizedDescription)\n", stderr)
                    return
                }
                guard let image = image,
                      let tiffData = image.tiffRepresentation,
                      let bitmapRep = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                    fputs("Warning: PNG encoding failed.\n", stderr)
                    return
                }
                
                let pngPath = baseOutput.appendingPathExtension("png").path
                do {
                    try pngData.write(to: URL(fileURLWithPath: pngPath))
                    files["png"] = pngPath
                } catch {
                    fputs("Warning: Failed to write PNG file: \(error.localizedDescription)\n", stderr)
                }
            })
        }
        
        // 4. Export Vector PDF
        if options.formats.contains("pdf") {
            group.enter()
            let pdfConfig = WKPDFConfiguration()
            pdfConfig.rect = CGRect(x: 0, y: 0, width: width, height: height)
            
            webView.createPDF(configuration: pdfConfig, completionHandler: { (result: Result<Data, Error>) in
                defer { group.leave() }
                switch result {
                case .success(let pdfData):
                    let pdfPath = baseOutput.appendingPathExtension("pdf").path
                    do {
                        try pdfData.write(to: URL(fileURLWithPath: pdfPath))
                        files["pdf"] = pdfPath
                    } catch {
                        fputs("Warning: Failed to write PDF file: \(error.localizedDescription)\n", stderr)
                    }
                case .failure(let error):
                    fputs("Warning: PDF export failed: \(error.localizedDescription)\n", stderr)
                }
            })
        }
        
        group.notify(queue: .main) {
            if self.options.jsonOutput {
                let outputObj: [String: Any] = [
                    "status": "success",
                    "theme": self.options.theme,
                    "width": Int(width),
                    "height": Int(height),
                    "files": files
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: outputObj, options: [.prettyPrinted]),
                   let jsonStr = String(data: jsonData, encoding: .utf8) {
                    print(jsonStr)
                }
            } else {
                print("Generated files:")
                for (fmt, path) in files {
                    print("  - [\(fmt.uppercased())]: \(path)")
                }
            }
            exit(0)
        }
    }
}

// MARK: - Execute
let html = buildHTML(diagramText: diagramSource, theme: options.theme, title: options.title)
let exporter = DiagramExporter(options: options, htmlContent: html)
exporter.start()

// Run headless RunLoop
RunLoop.main.run()
