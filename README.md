# nim-qpdf
Nim bindings for the [qpdf](https://qpdf.sourceforge.io) C++ library.

## Requirements

- [Nim](https://nim-lang.org) 2.0.6+
- [qpdf](https://qpdf.sourceforge.io) 11.0+ (`libqpdf-dev`)

## Installtion
```bash
nimble install qpdf
```

## Usage

```nim
import pkg/qpdf

# Create new PDF
var pdf = newPdf()

# Basic info
echo "Pages: ", pdf.numPages
echo "Version: ", pdf.version

# Add embedded file
pdf.addEmbeddedFile("data.txt", "content", "text/plain")

# Save
pdf.save("output.pdf")

# Or save to memory
let bytes = pdf.saveToMemory()
```

## Build

```bash
nim cpp -r yourfile.nim
```

### Nimble

Add the following lines to your .nimble:
```
backend = "cpp"
```
