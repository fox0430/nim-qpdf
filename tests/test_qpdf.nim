## Unit tests for qpdf-nim bindings

import std/[unittest, os]

import ../qpdf

suite "std::string":
  test "create from cstring":
    let s = initStdString("hello")
    check s.c_str() == "hello"
    check s.size() == 5

  test "toString":
    let s = initStdString("test")
    check toString(s) == "test"

  test "empty":
    let s = initStdString()
    check s.size() == 0

suite "QPDF core":
  test "version":
    let ver = qpdfVersion()
    check ver.size() > 0

  test "createQPDF":
    var qpdf = createQPDF()
    check not qpdf.isNil

  test "emptyPDF":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    check qpdf[].getAllPages().len == 0

suite "QPDFObjectHandle":
  test "null":
    let obj = newNull()
    check obj.isNull()

  test "bool":
    check newBool(true).getBoolValue() == true
    check newBool(false).getBoolValue() == false

  test "integer":
    check newInteger(42).getIntValue() == 42
    check newInteger(-100).getIntValue() == -100

  test "real":
    let obj = newReal(3.14, 2)
    check obj.isReal()

  test "name":
    let obj = newName(toStdString("/Test"))
    check obj.isName()

  test "string":
    let obj = newString(toStdString("Hello"))
    check obj.isString()

  test "array":
    var arr = newArray()
    arr.appendItem(newInteger(1))
    arr.appendItem(newInteger(2))
    check arr.getArrayNItems() == 2
    check arr.len == 2

  test "dictionary":
    var dict = newDictionary()
    dict["/Key"] = newInteger(123)
    check dict.contains("/Key")
    check dict["/Key"].getIntValue() == 123

suite "PdfDoc":
  test "newPdf":
    var pdf = newPdf()
    check not pdf.qpdf.isNil
    check pdf.numPages == 0

  test "version":
    var pdf = newPdf()
    check pdf.version.len > 0

  test "isEncrypted":
    var pdf = newPdf()
    check not pdf.isEncrypted

  test "root and trailer":
    var pdf = newPdf()
    check pdf.root.isDictionary
    check pdf.trailer.isDictionary

suite "Save":
  test "saveToMemory":
    var pdf = newPdf()
    let data = pdf.saveToMemory()
    check data.len > 0
    check data[0] == byte('%')
    check data[1] == byte('P')
    check data[2] == byte('D')
    check data[3] == byte('F')

  test "save to file":
    let tmpFile = getTempDir() / "test_qpdf.pdf"
    defer:
      removeFile(tmpFile)

    var pdf = newPdf()
    pdf.save(tmpFile)
    check fileExists(tmpFile)

    var pdf2 = openPdf(tmpFile)
    check pdf2.numPages == 0

suite "Embedded files":
  test "hasEmbeddedFiles":
    var pdf = newPdf()
    check not pdf.hasEmbeddedFiles

  test "addEmbeddedFile":
    var pdf = newPdf()
    pdf.addEmbeddedFile("test.txt", "Hello World", "text/plain")
    check pdf.hasEmbeddedFiles

suite "Metadata":
  test "get/set metadata":
    var pdf = newPdf()
    let xmp =
      """<?xml version="1.0"?><x:xmpmeta xmlns:x="adobe:ns:meta/"><test/></x:xmpmeta>"""
    pdf.setMetadata(xmp)
    let result = pdf.getMetadata()
    check result.len > 0
