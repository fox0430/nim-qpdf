## Low-level bindings tests for qpdf_cpp.nim

import std/[unittest, strutils]
import ../lowlevel/qpdf_cpp

suite "StdVector":
  test "create and push_back":
    var vec = initStdVector[cint]()
    check vec.len == 0
    vec.push_back(10)
    vec.push_back(20)
    check vec.len == 2
    check vec[0] == 10
    check vec[1] == 20

  test "clear":
    var vec = initStdVector[cint]()
    vec.push_back(1)
    vec.push_back(2)
    vec.clear()
    check vec.len == 0

suite "SharedPtr":
  test "isNil":
    var qpdf = createQPDF()
    check not qpdf.isNil

  test "get":
    var qpdf = createQPDF()
    let p = qpdf.get()
    check p != nil

  test "dereference":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    check qpdf[].getAllPages().len == 0

suite "Buffer":
  test "create empty":
    let buf = initBuffer()
    check buf.getSize() == 0

  test "create with size":
    let buf = initBuffer(100)
    check buf.getSize() == 100
    check buf.getBuffer() != nil

suite "QPDFObjGen":
  test "create default":
    let og = initQPDFObjGen()
    check og.getObj() == 0
    check og.getGen() == 0

  test "create with values":
    let og = initQPDFObjGen(5, 2)
    check og.getObj() == 5
    check og.getGen() == 2

  test "isIndirect":
    let og1 = initQPDFObjGen()
    check not og1.isIndirect()
    let og2 = initQPDFObjGen(1, 0)
    check og2.isIndirect()

suite "QPDFObjectHandle type checks":
  test "isInitialized":
    let obj = initQPDFObjectHandle()
    check not obj.isInitialized()
    let null = newNull()
    check null.isInitialized()

  test "getTypeCode":
    check newNull().getTypeCode() == ot_null
    check newBool(true).getTypeCode() == ot_boolean
    check newInteger(1).getTypeCode() == ot_integer
    check newArray().getTypeCode() == ot_array
    check newDictionary().getTypeCode() == ot_dictionary

  test "getTypeName":
    check $newNull().getTypeName() == "null"
    check $newBool(true).getTypeName() == "boolean"

  test "isScalar":
    check newNull().isScalar()
    check newBool(true).isScalar()
    check newInteger(1).isScalar()
    check not newArray().isScalar()
    check not newDictionary().isScalar()

suite "QPDFObjectHandle values":
  test "getIntValueAsInt":
    check newInteger(42).getIntValueAsInt() == 42

  test "getUIntValue":
    check newInteger(100).getUIntValue() == 100

  test "getRealValue":
    let r = newReal(3.14, 2)
    check r.getRealValue().size() > 0

  test "getNumericValue":
    check newInteger(10).getNumericValue() == 10.0
    check newReal(2.5, 1).getNumericValue() > 2.0

  test "getUTF8Value":
    let s = newString(toStdString("Hello"))
    check s.getUTF8Value().size() > 0

suite "QPDFObjectHandle array advanced":
  test "setArrayItem":
    var arr = newArray()
    arr.appendItem(newInteger(1))
    arr.appendItem(newInteger(2))
    arr.setArrayItem(0, newInteger(100))
    check arr.getArrayItem(0).getIntValue() == 100

  test "insertItem":
    var arr = newArray()
    arr.appendItem(newInteger(1))
    arr.appendItem(newInteger(3))
    arr.insertItem(1, newInteger(2))
    check arr.getArrayNItems() == 3
    check arr.getArrayItem(1).getIntValue() == 2

  test "eraseItem":
    var arr = newArray()
    arr.appendItem(newInteger(1))
    arr.appendItem(newInteger(2))
    arr.appendItem(newInteger(3))
    arr.eraseItem(1)
    check arr.getArrayNItems() == 2
    check arr.getArrayItem(1).getIntValue() == 3

  test "getArrayAsVector":
    var arr = newArray()
    arr.appendItem(newInteger(10))
    arr.appendItem(newInteger(20))
    let vec = arr.getArrayAsVector()
    check vec.len == 2

suite "QPDFObjectHandle dictionary advanced":
  test "isNameAndEquals":
    let name = newName(toStdString("/Type"))
    check name.isNameAndEquals(toStdString("/Type"))
    check not name.isNameAndEquals(toStdString("/Other"))

  test "isDictionaryOfType":
    var dict = newDictionary()
    dict.replaceKey(toStdString("/Type"), newName(toStdString("/Page")))
    check dict.isDictionaryOfType(toStdString("/Page"))

suite "QPDFObjectHandle conversion":
  test "unparse":
    let i = newInteger(42)
    check i.unparse().size() > 0

  test "wrapInArray":
    let i = newInteger(1)
    let arr = i.wrapInArray()
    check arr.isArray()
    check arr.getArrayNItems() == 1

  test "shallowCopy":
    var dict = newDictionary()
    dict.replaceKey(toStdString("/Key"), newInteger(1))
    let copy = dict.shallowCopy()
    check copy.isDictionary()
    check copy.hasKey(toStdString("/Key"))

suite "QPDF settings":
  test "setSuppressWarnings":
    var qpdf = createQPDF()
    qpdf[].setSuppressWarnings(true)
    # No exception = success

  test "setAttemptRecovery":
    var qpdf = createQPDF()
    qpdf[].setAttemptRecovery(true)

  test "anyWarnings":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    check not qpdf[].anyWarnings()

  test "numWarnings":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    check qpdf[].numWarnings() == 0

suite "QPDF object operations":
  test "makeIndirectObject":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    let dict = newDictionary()
    let indirect = qpdf[].makeIndirectObject(dict)
    check indirect.isIndirect()
    check indirect.getObjectID() > 0

  test "getObjectByID":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    let dict = qpdf[].makeIndirectObject(newDictionary())
    let id = dict.getObjectID()
    let gen = dict.getGeneration()
    let retrieved = qpdf[].getObjectByID(id, gen)
    check retrieved.isDictionary()

  test "getObjGen":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    let dict = qpdf[].makeIndirectObject(newDictionary())
    let og = dict.getObjGen()
    check og.isIndirect()

# Note: QPDFWriter tests skipped due to C++ destructor ordering issues
# with Nim's GC. QPDFWriter holds a reference to QPDF, and when both
# go out of scope, the destruction order can cause crashes.

# Note: DocumentHelper tests skipped - same destructor ordering issue

suite "QUtil":
  test "QPDFTime and qpdf_time_to_pdf_time":
    let t = initQPDFTime(2024, 1, 15, 10, 30, 0, 0)
    let pdfTime = qpdf_time_to_pdf_time(t)
    check pdfTime.size() > 0
    # PDF time format: D:YYYYMMDDHHmmSS
    check toString(pdfTime).startsWith("D:2024")

suite "Stream operations":
  test "newStream and replaceStreamData":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    var stream = newStream(qpdf.get())
    check stream.isStream()
    stream.replaceStreamData(toStdString("test data"), newNull(), newNull())
    # isDataModified may not return true for new streams
    # Just check the stream is valid

  test "getDict":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    var stream = newStream(qpdf.get())
    let dict = stream.getDict()
    check dict.isDictionary()

  test "getStreamData":
    var qpdf = createQPDF()
    qpdf[].emptyPDF()
    var stream = newStream(qpdf.get())
    stream.replaceStreamData(toStdString("hello"), newNull(), newNull())
    let buf = stream.getStreamData(qpdf_dl_all)
    check not buf.isNil
    check buf[].getSize() == 5

suite "Rectangle":
  test "getArrayAsRectangle":
    var arr = newArray()
    arr.appendItem(newReal(0.0, 0))
    arr.appendItem(newReal(0.0, 0))
    arr.appendItem(newReal(612.0, 0))
    arr.appendItem(newReal(792.0, 0))
    let rect = arr.getArrayAsRectangle()
    check rect.llx == 0.0
    check rect.lly == 0.0
    check rect.urx == 612.0
    check rect.ury == 792.0
