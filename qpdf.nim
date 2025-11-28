## qpdf - High-level Nim bindings for QPDF
##
## Usage:
##   nim cpp -r yourfile.nim
##
## Example:
##   var pdf = openPdf("input.pdf")
##   echo "Pages: ", pdf.numPages
##   pdf.save("output.pdf")

import lowlevel/qpdf_cpp

import std/times

export qpdf_cpp

type
  PdfDocObj = object ## Internal PDF document data
    qpdf*: SharedPtr[QPDF]

  PdfDoc* = ref PdfDocObj ## High-level PDF document wrapper (ref for safe seq usage)

  EmbeddedFile* = object ## Embedded file information
    name*: string
    mimeType*: string
    description*: string

# Document Operations

proc openPdf*(filename: string, password: string = ""): PdfDoc =
  ## Open an existing PDF file
  new(result)
  result.qpdf = createQPDF()
  if password.len > 0:
    result.qpdf[].processFile(filename.cstring, password.cstring)
  else:
    result.qpdf[].processFile(filename.cstring)

proc openPdfFromMemory*(
    data: string, description: string = "memory", password: string = ""
): PdfDoc =
  ## Open a PDF from memory buffer
  new(result)
  result.qpdf = createQPDF()
  if password.len > 0:
    result.qpdf[].processMemoryFile(
      description.cstring, data.cstring, data.len.csize_t, password.cstring
    )
  else:
    result.qpdf[].processMemoryFile(
      description.cstring, data.cstring, data.len.csize_t, nil
    )

proc newPdf*(): PdfDoc =
  ## Create a new empty PDF document
  new(result)
  result.qpdf = createQPDF()
  result.qpdf[].emptyPDF()

proc close*(pdf: PdfDoc) =
  ## Close the PDF and release resources
  if pdf != nil and not pdf.qpdf.isNil:
    pdf.qpdf[].closeInputSource()

proc save*(pdf: PdfDoc, filename: string, linearize: bool = false) =
  ## Save PDF to a file
  block writerScope:
    var writer = initQPDFWriter(pdf.qpdf[], filename.cstring)
    writer.setLinearization(linearize)
    writer.write()

proc saveToMemory*(pdf: PdfDoc, linearize: bool = false): seq[byte] =
  ## Save PDF to memory and return as byte sequence
  var bufPtr: SharedPtr[Buffer]

  block writerScope:
    var writer = initQPDFWriter(pdf.qpdf[])
    writer.setOutputMemory()
    writer.setLinearization(linearize)
    writer.write()
    bufPtr = writer.getBufferSharedPointer()

  if bufPtr.isNil:
    return @[]

  let size = bufPtr[].getSize()
  result = newSeq[byte](size)
  if size > 0:
    copyMem(addr result[0], bufPtr[].getBuffer(), size)

# Document Info

proc version*(pdf: PdfDoc): string =
  ## Get PDF version string (e.g., "1.7")
  let ver = pdf.qpdf[].getPDFVersion()
  toString(ver)

proc isEncrypted*(pdf: PdfDoc): bool =
  ## Check if PDF is encrypted
  pdf.qpdf[].isEncrypted()

proc isLinearized*(pdf: PdfDoc): bool =
  ## Check if PDF is linearized (optimized for web)
  pdf.qpdf[].isLinearized()

proc numPages*(pdf: PdfDoc): int =
  ## Get number of pages
  pdf.qpdf[].getAllPages().len.int

proc root*(pdf: PdfDoc): QPDFObjectHandle =
  ## Get document catalog (root dictionary)
  pdf.qpdf[].getRoot()

proc trailer*(pdf: PdfDoc): QPDFObjectHandle =
  ## Get document trailer dictionary
  pdf.qpdf[].getTrailer()

# Page Operations

proc getPage*(pdf: PdfDoc, index: int): QPDFObjectHandle =
  ## Get a page by index (0-based)
  let pages = pdf.qpdf[].getAllPages()
  if index >= 0 and index.csize_t < pages.len:
    return pages[index.csize_t]
  raise newException(IndexDefect, "Page index out of range: " & $index)

proc addPage*(pdf: PdfDoc, page: QPDFObjectHandle, first: bool = false) =
  ## Add a page to the document
  pdf.qpdf[].addPage(page, first)

proc removePage*(pdf: PdfDoc, index: int) =
  ## Remove a page by index
  let page = pdf.getPage(index)
  pdf.qpdf[].removePage(page)

proc copyPage*(src: PdfDoc, pageIndex: int, dest: var PdfDoc) =
  ## Copy a page from one PDF to another
  let srcPage = src.getPage(pageIndex)
  let foreignPage = dest.qpdf[].copyForeignObject(srcPage)
  dest.addPage(foreignPage)

# Embedded Files (Attachments)

proc hasEmbeddedFiles*(pdf: PdfDoc): bool =
  ## Check if PDF has any embedded files
  var helper = initQPDFEmbeddedFileDocumentHelper(pdf.qpdf[])
  helper.hasEmbeddedFiles()

proc addEmbeddedFile*(
    pdf: PdfDoc,
    filename: string,
    data: string,
    mimeType: string = "",
    description: string = "",
) =
  ## Add an embedded file (attachment) to the PDF
  var helper = initQPDFEmbeddedFileDocumentHelper(pdf.qpdf[])

  # Create embedded file stream
  var efStream = createEFStream(pdf.qpdf[], toStdString(data))

  # Set MIME type
  if mimeType.len > 0:
    discard efStream.setSubtype(toStdString(mimeType))

  # Set timestamps
  let now = now().utc
  let qpdfTime = initQPDFTime(
    now.year.cint, now.month.ord.cint, now.monthday.cint, now.hour.cint,
    now.minute.cint, now.second.cint, 0,
  )
  let pdfTime = qpdf_time_to_pdf_time(qpdfTime)
  discard efStream.setCreationDate(pdfTime)
  discard efStream.setModDate(pdfTime)

  # Create file spec
  var fileSpec = createFileSpec(pdf.qpdf[], toStdString(filename), efStream)

  if description.len > 0:
    discard fileSpec.setDescription(toStdString(description))

  # Add to embedded files
  helper.replaceEmbeddedFile(toStdString(filename), fileSpec)

proc removeEmbeddedFile*(pdf: PdfDoc, filename: string): bool =
  ## Remove an embedded file by name
  var helper = initQPDFEmbeddedFileDocumentHelper(pdf.qpdf[])
  helper.removeEmbeddedFile(toStdString(filename))

# Metadata

proc getMetadata*(pdf: PdfDoc): string =
  ## Get XMP metadata as XML string (empty if none)
  let root = pdf.qpdf[].getRoot()
  if not root.hasKey(toStdString("/Metadata")):
    return ""

  let metadata = root.getKey(toStdString("/Metadata"))
  if not metadata.isStream():
    return ""

  let buf = metadata.getStreamData(qpdf_dl_all)
  if buf.isNil:
    return ""

  result = newString(buf[].getSize())
  if result.len > 0:
    copyMem(addr result[0], buf[].getBuffer(), result.len)

proc setMetadata*(pdf: PdfDoc, xmp: string) =
  ## Set XMP metadata from XML string
  var root = pdf.qpdf[].getRoot()

  if root.hasKey(toStdString("/Metadata")):
    let existing = root.getKey(toStdString("/Metadata"))
    if existing.isStream():
      existing.replaceStreamData(toStdString(xmp), newNull(), newNull())
      return

  # Create new metadata stream
  var stream = newStream(pdf.qpdf.get())
  var dict = stream.getDict()
  dict.replaceKey(toStdString("/Type"), newName(toStdString("/Metadata")))
  dict.replaceKey(toStdString("/Subtype"), newName(toStdString("/XML")))
  stream.replaceStreamData(toStdString(xmp), newNull(), newNull())
  root.replaceKey(toStdString("/Metadata"), stream)

# Convenience

proc `[]`*(pdf: PdfDoc, index: int): QPDFObjectHandle =
  ## Get page by index: pdf[0] returns first page
  pdf.getPage(index)

iterator pages*(pdf: PdfDoc): QPDFObjectHandle =
  ## Iterate over all pages
  let allPages = pdf.qpdf[].getAllPages()
  for i in 0.csize_t ..< allPages.len:
    yield allPages[i]

# Warnings

proc anyWarnings*(pdf: PdfDoc): bool =
  ## Check if any warnings have been issued
  pdf.qpdf[].anyWarnings()

proc numWarnings*(pdf: PdfDoc): int =
  ## Get number of warnings issued
  pdf.qpdf[].numWarnings().int

proc setSuppressWarnings*(pdf: PdfDoc, suppress: bool) =
  ## Suppress warning output to stderr (warnings still tracked)
  pdf.qpdf[].setSuppressWarnings(suppress)

proc getWarnings*(pdf: PdfDoc): seq[string] =
  ## Get warning messages and clear the warning list
  var warnings = pdf.qpdf[].getWarnings()
  result = newSeq[string](warnings.len)
  for i in 0.csize_t ..< warnings.len:
    result[i.int] = $warnings.getWarningPtr(i).what()
