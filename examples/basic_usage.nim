## Basic usage example for qpdf Nim bindings
## Compile: nim cpp -r examples/basic_usage.nim

import pkg/qpdf

# Create a new PDF
var pdf = newPdf()
echo "Created new PDF, version: ", pdf.version

# Create a page with text (A4 size: 595 x 842 points)
var mediaBox = newArray()
mediaBox.appendItem(newInteger(0))
mediaBox.appendItem(newInteger(0))
mediaBox.appendItem(newInteger(595))
mediaBox.appendItem(newInteger(842))

# Set up font in resources
var fontDict = newDictionary()
fontDict.replaceKey(toStdString("/Type"), newName(toStdString("/Font")))
fontDict.replaceKey(toStdString("/Subtype"), newName(toStdString("/Type1")))
fontDict.replaceKey(toStdString("/BaseFont"), newName(toStdString("/Helvetica")))

var fonts = newDictionary()
fonts.replaceKey(toStdString("/F1"), fontDict)

var resources = newDictionary()
resources.replaceKey(toStdString("/Font"), fonts)

# Create content stream with text
let contentData = "BT /F1 24 Tf 50 750 Td (Hello from Nim!) Tj ET"
var contentStream = newStream(pdf.qpdf.get())
contentStream.replaceStreamData(toStdString(contentData), newNull(), newNull())

var page = newDictionary()
page.replaceKey(toStdString("/Type"), newName(toStdString("/Page")))
page.replaceKey(toStdString("/MediaBox"), mediaBox)
page.replaceKey(toStdString("/Resources"), resources)
page.replaceKey(toStdString("/Contents"), contentStream)
pdf.addPage(page)

echo "Number of pages: ", pdf.numPages

# Add metadata
pdf.setMetadata(
  """<?xml version="1.0" encoding="UTF-8"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:title>Example PDF</dc:title>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>"""
)

# Add an embedded file (attachment)
pdf.addEmbeddedFile(
  filename = "hello.txt",
  data = "Hello from Nim!",
  mimeType = "text/plain",
  description = "A simple text file",
)

echo "Has embedded files: ", pdf.hasEmbeddedFiles

# Save to file
pdf.save("./output.pdf")
echo "Saved to ./output.pdf"

# Save to memory
let bytes = pdf.saveToMemory()
echo "PDF size in memory: ", bytes.len, " bytes"

# Check warnings
if pdf.anyWarnings:
  echo "Warnings: ", pdf.getWarnings()
