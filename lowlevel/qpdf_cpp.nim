## qpdf_cpp - Direct C++ bindings for qpdf library
##
## Note: This module requires the C++ backend.

{.passL: "-lqpdf".}
{.push header: "<qpdf/QPDF.hh>".}

# Forward declarations and basic types

type
  # std::string binding
  StdString* {.importcpp: "std::string", header: "<string>".} = object

  # std::shared_ptr binding
  SharedPtr*[T] {.importcpp: "std::shared_ptr<'0>", header: "<memory>".} = object

  # std::vector binding
  StdVector*[T] {.importcpp: "std::vector<'0>", header: "<vector>".} = object

  # std::map binding
  StdMap*[K, V] {.importcpp: "std::map<'0, '1>", header: "<map>".} = object

  # std::set binding
  StdSet*[T] {.importcpp: "std::set<'0>", header: "<set>".} = object

# std::string operations
proc initStdString*(): StdString {.importcpp: "std::string()", constructor.}
proc initStdString*(s: cstring): StdString {.importcpp: "std::string(@)", constructor.}
proc initStdString*(
  s: cstring, len: csize_t
): StdString {.importcpp: "std::string(@)", constructor.}

proc c_str*(s: StdString): cstring {.importcpp: "#.c_str()".}
proc size*(s: StdString): csize_t {.importcpp: "#.size()".}
proc data*(s: StdString): ptr char {.importcpp: "#.data()".}

template toString*(s: StdString): string =
  ## Convert std::string to Nim string
  block:
    let cs = s.c_str()
    let length = s.size()
    var res: string
    if cs != nil and length > 0:
      res = newString(length)
      copyMem(addr res[0], cs, length)
    else:
      res = ""
    res

template `$`*(s: StdString): string =
  toString(s)

# Use inline C++ code for toStdString to avoid scope issues
template toStdString*(s: string): StdString =
  initStdString(s.cstring, s.len.csize_t)

# std::vector operations
proc initStdVector*[T](): StdVector[T] {.importcpp: "std::vector<'*0>()", constructor.}
proc len*[T](v: StdVector[T]): csize_t {.importcpp: "#.size()".}
proc `[]`*[T](v: StdVector[T], i: csize_t): T {.importcpp: "#[#]".}
proc push_back*[T](v: var StdVector[T], val: T) {.importcpp: "#.push_back(@)".}
proc clear*[T](v: var StdVector[T]) {.importcpp: "#.clear()".}

# std::shared_ptr operations
proc isNil*[T](p: SharedPtr[T]): bool {.importcpp: "(# == nullptr)".}
proc `[]`*[T](p: SharedPtr[T]): var T {.importcpp: "(*#)".}
proc get*[T](p: SharedPtr[T]): ptr T {.importcpp: "#.get()".}
proc reset*[T](p: var SharedPtr[T]) {.importcpp: "#.reset()".}

{.pop.}

# C++ exception handling helper
# Nim doesn't convert C++ exceptions to Nim exceptions properly,
# but we can retrieve the message using std::current_exception()
{.
  emit:
    """
#include <string>
#include <exception>
static std::string _currentCppExceptionMsg;
"""
.}

proc getCurrentCppExceptionMsgImpl() {.
  importcpp:
    """
  _currentCppExceptionMsg.clear();
  try {
    if (auto eptr = std::current_exception()) {
      std::rethrow_exception(eptr);
    }
  } catch (const std::exception& e) {
    _currentCppExceptionMsg = e.what();
  } catch (...) {
    _currentCppExceptionMsg = "unknown C++ exception";
  }
"""
.}

proc getCurrentCppExceptionMsgPtr(): cstring {.
  importcpp: "_currentCppExceptionMsg.c_str()"
.}

proc getCurrentCppExceptionMsg*(): string =
  ## Get the current C++ exception message (call from except block)
  getCurrentCppExceptionMsgImpl()
  $getCurrentCppExceptionMsgPtr()

# Constants (from qpdf/Constants.h)

type
  QpdfObjectType* {.size: sizeof(cint).} = enum
    ot_uninitialized = 0
    ot_reserved = 1
    ot_null = 2
    ot_boolean = 3
    ot_integer = 4
    ot_real = 5
    ot_string = 6
    ot_name = 7
    ot_array = 8
    ot_dictionary = 9
    ot_stream = 10
    ot_operator = 11
    ot_inlineimage = 12
    ot_unresolved = 13
    ot_destroyed = 14
    ot_reference = 15

  QpdfStreamDecodeLevel* {.size: sizeof(cint).} = enum
    qpdf_dl_none = 0
    qpdf_dl_generalized = 1
    qpdf_dl_specialized = 2
    qpdf_dl_all = 3

  QpdfStreamDataMode* {.size: sizeof(cint).} = enum
    qpdf_s_uncompress = 0
    qpdf_s_preserve = 1
    qpdf_s_compress = 2

  QpdfObjectStreamMode* {.size: sizeof(cint).} = enum
    qpdf_o_disable = 0
    qpdf_o_preserve = 1
    qpdf_o_generate = 2

  QpdfR3PrintMode* {.size: sizeof(cint).} = enum
    qpdf_r3p_full = 0
    qpdf_r3p_low = 1
    qpdf_r3p_none = 2

# Buffer class

{.push header: "<qpdf/Buffer.hh>".}

type Buffer* {.importcpp: "Buffer".} = object

proc initBuffer*(): Buffer {.importcpp: "Buffer()", constructor.}
proc initBuffer*(size: csize_t): Buffer {.importcpp: "Buffer(@)", constructor.}
proc getBuffer*(b: Buffer): ptr uint8 {.importcpp: "#.getBuffer()".}
proc getSize*(b: Buffer): csize_t {.importcpp: "#.getSize()".}

{.pop.}

# QPDFObjGen class

{.push header: "<qpdf/QPDFObjGen.hh>".}

type QPDFObjGen* {.importcpp: "QPDFObjGen".} = object

proc initQPDFObjGen*(): QPDFObjGen {.importcpp: "QPDFObjGen()", constructor.}
proc initQPDFObjGen*(
  obj: cint, gen: cint
): QPDFObjGen {.importcpp: "QPDFObjGen(@)", constructor.}

proc getObj*(og: QPDFObjGen): cint {.importcpp: "#.getObj()".}
proc getGen*(og: QPDFObjGen): cint {.importcpp: "#.getGen()".}
proc isIndirect*(og: QPDFObjGen): bool {.importcpp: "#.isIndirect()".}

{.pop.}

# QPDFObjectHandle class

{.push header: "<qpdf/QPDFObjectHandle.hh>".}

type
  QPDFObjectHandle* {.importcpp: "QPDFObjectHandle".} = object

  Rectangle* {.importcpp: "QPDFObjectHandle::Rectangle".} = object
    llx*: cdouble
    lly*: cdouble
    urx*: cdouble
    ury*: cdouble

# Constructors
proc initQPDFObjectHandle*(): QPDFObjectHandle {.
  importcpp: "QPDFObjectHandle()", constructor
.}

# Type checking
proc isInitialized*(oh: QPDFObjectHandle): bool {.importcpp: "#.isInitialized()".}
proc getTypeCode*(oh: QPDFObjectHandle): QpdfObjectType {.importcpp: "#.getTypeCode()".}
proc getTypeName*(oh: QPDFObjectHandle): cstring {.importcpp: "#.getTypeName()".}
proc isBool*(oh: QPDFObjectHandle): bool {.importcpp: "#.isBool()".}
proc isNull*(oh: QPDFObjectHandle): bool {.importcpp: "#.isNull()".}
proc isInteger*(oh: QPDFObjectHandle): bool {.importcpp: "#.isInteger()".}
proc isReal*(oh: QPDFObjectHandle): bool {.importcpp: "#.isReal()".}
proc isName*(oh: QPDFObjectHandle): bool {.importcpp: "#.isName()".}
proc isString*(oh: QPDFObjectHandle): bool {.importcpp: "#.isString()".}
proc isOperator*(oh: QPDFObjectHandle): bool {.importcpp: "#.isOperator()".}
proc isInlineImage*(oh: QPDFObjectHandle): bool {.importcpp: "#.isInlineImage()".}
proc isArray*(oh: QPDFObjectHandle): bool {.importcpp: "#.isArray()".}
proc isDictionary*(oh: QPDFObjectHandle): bool {.importcpp: "#.isDictionary()".}
proc isStream*(oh: QPDFObjectHandle): bool {.importcpp: "#.isStream()".}
proc isIndirect*(oh: QPDFObjectHandle): bool {.importcpp: "#.isIndirect()".}
proc isScalar*(oh: QPDFObjectHandle): bool {.importcpp: "#.isScalar()".}
proc isReserved*(oh: QPDFObjectHandle): bool {.importcpp: "#.isReserved()".}
proc isDestroyed*(oh: QPDFObjectHandle): bool {.importcpp: "#.isDestroyed()".}
proc isNameAndEquals*(
  oh: QPDFObjectHandle, name: StdString
): bool {.importcpp: "#.isNameAndEquals(@)".}

proc isDictionaryOfType*(
  oh: QPDFObjectHandle, typ: StdString, subtype: StdString = initStdString()
): bool {.importcpp: "#.isDictionaryOfType(@)".}

proc isStreamOfType*(
  oh: QPDFObjectHandle, typ: StdString, subtype: StdString = initStdString()
): bool {.importcpp: "#.isStreamOfType(@)".}

# Value getters
proc getBoolValue*(oh: QPDFObjectHandle): bool {.importcpp: "#.getBoolValue()".}
proc getIntValue*(oh: QPDFObjectHandle): clonglong {.importcpp: "#.getIntValue()".}
proc getIntValueAsInt*(oh: QPDFObjectHandle): cint {.importcpp: "#.getIntValueAsInt()".}
proc getUIntValue*(oh: QPDFObjectHandle): culonglong {.importcpp: "#.getUIntValue()".}
proc getRealValue*(oh: QPDFObjectHandle): StdString {.importcpp: "#.getRealValue()".}
proc getNumericValue*(
  oh: QPDFObjectHandle
): cdouble {.importcpp: "#.getNumericValue()".}

proc getName*(oh: QPDFObjectHandle): StdString {.importcpp: "#.getName()".}
proc getStringValue*(
  oh: QPDFObjectHandle
): StdString {.importcpp: "#.getStringValue()".}

proc getUTF8Value*(oh: QPDFObjectHandle): StdString {.importcpp: "#.getUTF8Value()".}
proc getOperatorValue*(
  oh: QPDFObjectHandle
): StdString {.importcpp: "#.getOperatorValue()".}

# Object ID
proc getObjGen*(oh: QPDFObjectHandle): QPDFObjGen {.importcpp: "#.getObjGen()".}
proc getObjectID*(oh: QPDFObjectHandle): cint {.importcpp: "#.getObjectID()".}
proc getGeneration*(oh: QPDFObjectHandle): cint {.importcpp: "#.getGeneration()".}

# Array operations
proc getArrayNItems*(oh: QPDFObjectHandle): cint {.importcpp: "#.getArrayNItems()".}
proc getArrayItem*(
  oh: QPDFObjectHandle, n: cint
): QPDFObjectHandle {.importcpp: "#.getArrayItem(@)".}

proc setArrayItem*(
  oh: QPDFObjectHandle, n: cint, item: QPDFObjectHandle
) {.importcpp: "#.setArrayItem(@)".}

proc insertItem*(
  oh: QPDFObjectHandle, n: cint, item: QPDFObjectHandle
) {.importcpp: "#.insertItem(@)".}

proc appendItem*(
  oh: QPDFObjectHandle, item: QPDFObjectHandle
) {.importcpp: "#.appendItem(@)".}

proc eraseItem*(oh: QPDFObjectHandle, n: cint) {.importcpp: "#.eraseItem(@)".}
proc getArrayAsVector*(
  oh: QPDFObjectHandle
): StdVector[QPDFObjectHandle] {.importcpp: "#.getArrayAsVector()".}

# Dictionary operations
proc hasKey*(oh: QPDFObjectHandle, key: StdString): bool {.importcpp: "#.hasKey(@)".}
proc getKey*(
  oh: QPDFObjectHandle, key: StdString
): QPDFObjectHandle {.importcpp: "#.getKey(@)".}

proc getKeys*(oh: QPDFObjectHandle): StdSet[StdString] {.importcpp: "#.getKeys()".}
proc replaceKey*(
  oh: QPDFObjectHandle, key: StdString, value: QPDFObjectHandle
) {.importcpp: "#.replaceKey(@)".}

proc removeKey*(oh: QPDFObjectHandle, key: StdString) {.importcpp: "#.removeKey(@)".}
proc replaceOrRemoveKey*(
  oh: QPDFObjectHandle, key: StdString, value: QPDFObjectHandle
) {.importcpp: "#.replaceOrRemoveKey(@)".}

# Stream operations
proc getDict*(oh: QPDFObjectHandle): QPDFObjectHandle {.importcpp: "#.getDict()".}
proc isDataModified*(oh: QPDFObjectHandle): bool {.importcpp: "#.isDataModified()".}
proc getStreamData*(
  oh: QPDFObjectHandle, level: QpdfStreamDecodeLevel = qpdf_dl_generalized
): SharedPtr[Buffer] {.importcpp: "#.getStreamData(@)".}

proc getRawStreamData*(
  oh: QPDFObjectHandle
): SharedPtr[Buffer] {.importcpp: "#.getRawStreamData()".}

proc replaceStreamData*(
  oh: QPDFObjectHandle,
  data: StdString,
  filter: QPDFObjectHandle,
  decodeParms: QPDFObjectHandle,
) {.importcpp: "#.replaceStreamData(@)".}

# Object creation (static methods)
proc newNull*(): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newNull()".}
proc newBool*(val: bool): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newBool(@)".}
proc newInteger*(
  val: clonglong
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newInteger(@)".}

proc newReal*(
  val: StdString
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newReal(@)".}

proc newReal*(
  val: cdouble, decPlaces: cint = 0
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newReal(@)".}

proc newName*(
  name: StdString
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newName(@)".}

proc newString*(
  str: StdString
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newString(@)".}

proc newUnicodeString*(
  str: StdString
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newUnicodeString(@)".}

proc newArray*(): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newArray()".}
proc newArray*(
  items: StdVector[QPDFObjectHandle]
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newArray(@)".}

proc newDictionary*(): QPDFObjectHandle {.
  importcpp: "QPDFObjectHandle::newDictionary()"
.}

proc parse*(
  objStr: StdString
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::parse(@)".}

# Note: newStream(QPDF&) is defined after QPDF type

# Conversion
proc unparse*(oh: QPDFObjectHandle): StdString {.importcpp: "#.unparse()".}
proc unparseResolved*(
  oh: QPDFObjectHandle
): StdString {.importcpp: "#.unparseResolved()".}

proc unparseBinary*(oh: QPDFObjectHandle): StdString {.importcpp: "#.unparseBinary()".}
proc wrapInArray*(
  oh: QPDFObjectHandle
): QPDFObjectHandle {.importcpp: "#.wrapInArray()".}

proc shallowCopy*(
  oh: QPDFObjectHandle
): QPDFObjectHandle {.importcpp: "#.shallowCopy()".}

proc makeDirect*(oh: var QPDFObjectHandle) {.importcpp: "#.makeDirect()".}

# Rectangle
proc getArrayAsRectangle*(
  oh: QPDFObjectHandle
): Rectangle {.importcpp: "#.getArrayAsRectangle()".}

{.pop.}

# QPDF class

{.push header: "<qpdf/QPDF.hh>".}

type QPDF* {.importcpp: "QPDF".} = object

# Static methods
proc qpdfVersion*(): StdString {.importcpp: "QPDF::QPDFVersion()".}
proc createQPDF*(): SharedPtr[QPDF] {.importcpp: "QPDF::create()".}

# Use createQPDF() which returns SharedPtr[QPDF] for safe memory management

# Process methods
proc processFile*(
  qpdf: var QPDF, filename: cstring, password: cstring = nil
) {.importcpp: "#.processFile(@)".}

proc processMemoryFile*(
  qpdf: var QPDF,
  description: cstring,
  buf: cstring,
  length: csize_t,
  password: cstring = nil,
) {.importcpp: "#.processMemoryFile(@)".}

proc emptyPDF*(qpdf: var QPDF) {.importcpp: "#.emptyPDF()".}
proc createFromJSON*(
  qpdf: var QPDF, jsonFile: StdString
) {.importcpp: "#.createFromJSON(@)".}

proc updateFromJSON*(
  qpdf: var QPDF, jsonFile: StdString
) {.importcpp: "#.updateFromJSON(@)".}

proc closeInputSource*(qpdf: var QPDF) {.importcpp: "#.closeInputSource()".}

# Settings
proc setSuppressWarnings*(
  qpdf: var QPDF, val: bool
) {.importcpp: "#.setSuppressWarnings(@)".}

proc setAttemptRecovery*(
  qpdf: var QPDF, val: bool
) {.importcpp: "#.setAttemptRecovery(@)".}

proc setIgnoreXRefStreams*(
  qpdf: var QPDF, val: bool
) {.importcpp: "#.setIgnoreXRefStreams(@)".}

proc setImmediateCopyFrom*(
  qpdf: var QPDF, val: bool
) {.importcpp: "#.setImmediateCopyFrom(@)".}

proc setPasswordIsHexKey*(
  qpdf: var QPDF, val: bool
) {.importcpp: "#.setPasswordIsHexKey(@)".}

# Warnings
proc anyWarnings*(qpdf: QPDF): bool {.importcpp: "#.anyWarnings()".}
proc numWarnings*(qpdf: QPDF): csize_t {.importcpp: "#.numWarnings()".}

# QPDFExc - exception/warning info (no default constructor)
type QPDFExc* {.importcpp: "QPDFExc", header: "<qpdf/QPDFExc.hh>", bycopy.} = object

proc getErrorCode*(exc: ptr QPDFExc): cint {.importcpp: "#->getErrorCode()".}
proc getFilename*(exc: ptr QPDFExc): StdString {.importcpp: "#->getFilename()".}
proc getObject*(exc: ptr QPDFExc): StdString {.importcpp: "#->getObject()".}
proc getFilePosition*(exc: ptr QPDFExc): clonglong {.importcpp: "#->getFilePosition()".}
proc getMessageDetail*(
  exc: ptr QPDFExc
): StdString {.importcpp: "#->getMessageDetail()".}

proc what*(exc: ptr QPDFExc): cstring {.importcpp: "#->what()".}

proc getWarnings*(qpdf: var QPDF): StdVector[QPDFExc] {.importcpp: "#.getWarnings()".}

# Helper to get pointer to element in vector (for types without default constructor)
proc getWarningPtr*(
  v: var StdVector[QPDFExc], i: csize_t
): ptr QPDFExc {.importcpp: "(&((#)[#]))".}

# PDF info
proc getPDFVersion*(qpdf: QPDF): StdString {.importcpp: "#.getPDFVersion()".}
proc getExtensionLevel*(qpdf: QPDF): cint {.importcpp: "#.getExtensionLevel()".}
proc isLinearized*(qpdf: var QPDF): bool {.importcpp: "#.isLinearized()".}
proc isEncrypted*(qpdf: var QPDF): bool {.importcpp: "#.isEncrypted()".}
proc getFilename*(qpdf: QPDF): StdString {.importcpp: "#.getFilename()".}

# Object access
proc getTrailer*(qpdf: var QPDF): QPDFObjectHandle {.importcpp: "#.getTrailer()".}
proc getRoot*(qpdf: var QPDF): QPDFObjectHandle {.importcpp: "#.getRoot()".}
proc getObjectByID*(
  qpdf: var QPDF, objid: cint, generation: cint
): QPDFObjectHandle {.importcpp: "#.getObjectByID(@)".}

proc getObjectByObjGen*(
  qpdf: var QPDF, og: QPDFObjGen
): QPDFObjectHandle {.importcpp: "#.getObjectByObjGen(@)".}

proc makeIndirectObject*(
  qpdf: var QPDF, oh: QPDFObjectHandle
): QPDFObjectHandle {.importcpp: "#.makeIndirectObject(@)".}

proc replaceObject*(
  qpdf: var QPDF, objid: cint, generation: cint, oh: QPDFObjectHandle
) {.importcpp: "#.replaceObject(@)".}

proc replaceObject*(
  qpdf: var QPDF, og: QPDFObjGen, oh: QPDFObjectHandle
) {.importcpp: "#.replaceObject(@)".}

proc swapObjects*(
  qpdf: var QPDF, og1: QPDFObjGen, og2: QPDFObjGen
) {.importcpp: "#.swapObjects(@)".}

proc copyForeignObject*(
  qpdf: var QPDF, foreign: QPDFObjectHandle
): QPDFObjectHandle {.importcpp: "#.copyForeignObject(@)".}

# Pages
proc getAllPages*(
  qpdf: var QPDF
): StdVector[QPDFObjectHandle] {.importcpp: "#.getAllPages()".}

proc addPage*(
  qpdf: var QPDF, page: QPDFObjectHandle, first: bool
) {.importcpp: "#.addPage(@)".}

proc addPageAt*(
  qpdf: var QPDF, page: QPDFObjectHandle, before: bool, refPage: QPDFObjectHandle
) {.importcpp: "#.addPageAt(@)".}

proc removePage*(
  qpdf: var QPDF, page: QPDFObjectHandle
) {.importcpp: "#.removePage(@)".}

proc updateAllPagesCache*(qpdf: var QPDF) {.importcpp: "#.updateAllPagesCache()".}

{.pop.}

# QPDFObjectHandle::newStream requires QPDF, so defined here after QPDF type
{.push header: "<qpdf/QPDFObjectHandle.hh>".}
proc newStream*(
  qpdf: ptr QPDF
): QPDFObjectHandle {.importcpp: "QPDFObjectHandle::newStream(@)".}

{.pop.}

# QPDFWriter class

{.push header: "<qpdf/QPDFWriter.hh>".}

type QPDFWriter* {.importcpp: "QPDFWriter".} = object

# Constructors
proc initQPDFWriter*(
  qpdf: var QPDF
): QPDFWriter {.importcpp: "QPDFWriter(@)", constructor.}

proc initQPDFWriter*(
  qpdf: var QPDF, filename: cstring
): QPDFWriter {.importcpp: "QPDFWriter(@)", constructor.}

# Output destination
proc setOutputFilename*(
  w: var QPDFWriter, filename: cstring
) {.importcpp: "#.setOutputFilename(@)".}

proc setOutputMemory*(w: var QPDFWriter) {.importcpp: "#.setOutputMemory()".}
proc getBufferSharedPointer*(
  w: var QPDFWriter
): SharedPtr[Buffer] {.importcpp: "#.getBufferSharedPointer()".}

# PDF version
proc setMinimumPDFVersion*(
  w: var QPDFWriter, version: StdString
) {.importcpp: "#.setMinimumPDFVersion(@)".}

proc setMinimumPDFVersion*(
  w: var QPDFWriter, version: StdString, extensionLevel: cint
) {.importcpp: "#.setMinimumPDFVersion(@)".}

proc forcePDFVersion*(
  w: var QPDFWriter, version: StdString
) {.importcpp: "#.forcePDFVersion(@)".}

proc forcePDFVersion*(
  w: var QPDFWriter, version: StdString, extensionLevel: cint
) {.importcpp: "#.forcePDFVersion(@)".}

# Stream handling
proc setObjectStreamMode*(
  w: var QPDFWriter, mode: QpdfObjectStreamMode
) {.importcpp: "#.setObjectStreamMode(@)".}

proc setStreamDataMode*(
  w: var QPDFWriter, mode: QpdfStreamDataMode
) {.importcpp: "#.setStreamDataMode(@)".}

proc setDecodeLevel*(
  w: var QPDFWriter, level: QpdfStreamDecodeLevel
) {.importcpp: "#.setDecodeLevel(@)".}

proc setCompressStreams*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setCompressStreams(@)".}

proc setContentNormalization*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setContentNormalization(@)".}

proc setQDFMode*(w: var QPDFWriter, val: bool) {.importcpp: "#.setQDFMode(@)".}
proc setPreserveUnreferencedObjects*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setPreserveUnreferencedObjects(@)".}

proc setNewlineBeforeEndstream*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setNewlineBeforeEndstream(@)".}

# Encryption
proc setPreserveEncryption*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setPreserveEncryption(@)".}

proc setR6EncryptionParameters*(
  w: var QPDFWriter,
  userPassword: cstring,
  ownerPassword: cstring,
  allowAccessibility: bool,
  allowExtract: bool,
  allowAssemble: bool,
  allowAnnotateAndForm: bool,
  allowFormFilling: bool,
  allowModifyOther: bool,
  print: QpdfR3PrintMode,
  encryptMetadata: bool,
) {.importcpp: "#.setR6EncryptionParameters(@)".}

# Linearization
proc setLinearization*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setLinearization(@)".}

# ID
proc setDeterministicID*(
  w: var QPDFWriter, val: bool
) {.importcpp: "#.setDeterministicID(@)".}

proc setStaticID*(w: var QPDFWriter, val: bool) {.importcpp: "#.setStaticID(@)".}

# Write
proc write*(w: var QPDFWriter) {.importcpp: "#.write()".}

{.pop.}

# QPDFPageObjectHelper class

{.push header: "<qpdf/QPDFPageObjectHelper.hh>".}

type QPDFPageObjectHelper* {.importcpp: "QPDFPageObjectHelper".} = object

proc initQPDFPageObjectHelper*(
  oh: QPDFObjectHandle
): QPDFPageObjectHelper {.importcpp: "QPDFPageObjectHelper(@)", constructor.}

proc getObjectHandle*(
  h: QPDFPageObjectHelper
): QPDFObjectHandle {.importcpp: "#.getObjectHandle()".}

proc getAttribute*(
  h: QPDFPageObjectHelper, name: StdString, copyIfShared: bool
): QPDFObjectHandle {.importcpp: "#.getAttribute(@)".}

proc getMediaBox*(
  h: QPDFPageObjectHelper, copyIfShared: bool = false
): Rectangle {.importcpp: "#.getMediaBox(@)".}

proc getCropBox*(
  h: QPDFPageObjectHelper, copyIfShared: bool = false
): Rectangle {.importcpp: "#.getCropBox(@)".}

proc getTrimBox*(
  h: QPDFPageObjectHelper, copyIfShared: bool = false
): Rectangle {.importcpp: "#.getTrimBox(@)".}

proc getArtBox*(
  h: QPDFPageObjectHelper, copyIfShared: bool = false
): Rectangle {.importcpp: "#.getArtBox(@)".}

proc getBleedBox*(
  h: QPDFPageObjectHelper, copyIfShared: bool = false
): Rectangle {.importcpp: "#.getBleedBox(@)".}

proc rotatePage*(
  h: QPDFPageObjectHelper, angle: cint, relative: bool
) {.importcpp: "#.rotatePage(@)".}

proc getRotation*(h: QPDFPageObjectHelper): cint {.importcpp: "#.getRotation()".}
proc coalesceContentStreams*(
  h: var QPDFPageObjectHelper
) {.importcpp: "#.coalesceContentStreams()".}

proc externalizeInlineImages*(
  h: var QPDFPageObjectHelper, minSize: csize_t = 1024
) {.importcpp: "#.externalizeInlineImages(@)".}

proc removeUnreferencedResources*(
  h: var QPDFPageObjectHelper
) {.importcpp: "#.removeUnreferencedResources()".}

proc flattenRotation*(
  h: var QPDFPageObjectHelper
): QPDFPageObjectHelper {.importcpp: "#.flattenRotation()".}

{.pop.}

# QPDFPageDocumentHelper class

{.push header: "<qpdf/QPDFPageDocumentHelper.hh>".}

type QPDFPageDocumentHelper* {.importcpp: "QPDFPageDocumentHelper".} = object

proc initQPDFPageDocumentHelper*(
  qpdf: var QPDF
): QPDFPageDocumentHelper {.importcpp: "QPDFPageDocumentHelper(@)", constructor.}

proc getAllPages*(
  h: var QPDFPageDocumentHelper
): StdVector[QPDFPageObjectHelper] {.importcpp: "#.getAllPages()".}

proc addPage*(
  h: var QPDFPageDocumentHelper, page: QPDFObjectHandle, first: bool
) {.importcpp: "#.addPage(@)".}

proc addPageAt*(
  h: var QPDFPageDocumentHelper,
  page: QPDFObjectHandle,
  before: bool,
  refPage: QPDFPageObjectHelper,
) {.importcpp: "#.addPageAt(@)".}

proc removePage*(
  h: var QPDFPageDocumentHelper, page: QPDFPageObjectHelper
) {.importcpp: "#.removePage(@)".}

proc pushInheritedAttributesToPage*(
  h: var QPDFPageDocumentHelper
) {.importcpp: "#.pushInheritedAttributesToPage()".}

proc removeUnreferencedResources*(
  h: var QPDFPageDocumentHelper
) {.importcpp: "#.removeUnreferencedResources()".}

proc flattenAnnotations*(
  h: var QPDFPageDocumentHelper, requiredFlags: cint = 0, forbiddenFlags: cint = 0
) {.importcpp: "#.flattenAnnotations(@)".}

{.pop.}

# QPDFEFStreamObjectHelper class (Embedded File Stream)

{.push header: "<qpdf/QPDFEFStreamObjectHelper.hh>".}

type QPDFEFStreamObjectHelper* {.importcpp: "QPDFEFStreamObjectHelper".} = object

proc initQPDFEFStreamObjectHelper*(
  oh: QPDFObjectHandle
): QPDFEFStreamObjectHelper {.importcpp: "QPDFEFStreamObjectHelper(@)", constructor.}

proc createEFStream*(
  qpdf: var QPDF, data: StdString
): QPDFEFStreamObjectHelper {.importcpp: "QPDFEFStreamObjectHelper::createEFStream(@)".}

proc getObjectHandle*(
  h: QPDFEFStreamObjectHelper
): QPDFObjectHandle {.importcpp: "#.getObjectHandle()".}

proc setSubtype*(
  h: var QPDFEFStreamObjectHelper, subtype: StdString
): var QPDFEFStreamObjectHelper {.importcpp: "#.setSubtype(@)".}

proc setCreationDate*(
  h: var QPDFEFStreamObjectHelper, date: StdString
): var QPDFEFStreamObjectHelper {.importcpp: "#.setCreationDate(@)".}

proc setModDate*(
  h: var QPDFEFStreamObjectHelper, date: StdString
): var QPDFEFStreamObjectHelper {.importcpp: "#.setModDate(@)".}

proc getCreationDate*(
  h: QPDFEFStreamObjectHelper
): StdString {.importcpp: "#.getCreationDate()".}

proc getModDate*(h: QPDFEFStreamObjectHelper): StdString {.importcpp: "#.getModDate()".}
proc getSize*(h: QPDFEFStreamObjectHelper): csize_t {.importcpp: "#.getSize()".}
proc getSubtype*(h: QPDFEFStreamObjectHelper): StdString {.importcpp: "#.getSubtype()".}
proc getChecksum*(
  h: QPDFEFStreamObjectHelper
): StdString {.importcpp: "#.getChecksum()".}

{.pop.}

# QPDFFileSpecObjectHelper class

{.push header: "<qpdf/QPDFFileSpecObjectHelper.hh>".}

type QPDFFileSpecObjectHelper* {.importcpp: "QPDFFileSpecObjectHelper".} = object

proc initQPDFFileSpecObjectHelper*(
  oh: QPDFObjectHandle
): QPDFFileSpecObjectHelper {.importcpp: "QPDFFileSpecObjectHelper(@)", constructor.}

proc createFileSpec*(
  qpdf: var QPDF, filename: StdString, ef: QPDFEFStreamObjectHelper
): QPDFFileSpecObjectHelper {.importcpp: "QPDFFileSpecObjectHelper::createFileSpec(@)".}

proc getObjectHandle*(
  h: QPDFFileSpecObjectHelper
): QPDFObjectHandle {.importcpp: "#.getObjectHandle()".}

proc getDescription*(
  h: QPDFFileSpecObjectHelper
): StdString {.importcpp: "#.getDescription()".}

proc getFilename*(
  h: QPDFFileSpecObjectHelper
): StdString {.importcpp: "#.getFilename()".}

proc setDescription*(
  h: var QPDFFileSpecObjectHelper, desc: StdString
): var QPDFFileSpecObjectHelper {.importcpp: "#.setDescription(@)".}

proc setFilename*(
  h: var QPDFFileSpecObjectHelper, filename: StdString
): var QPDFFileSpecObjectHelper {.importcpp: "#.setFilename(@)".}

proc getEmbeddedFileStream*(
  h: QPDFFileSpecObjectHelper
): QPDFObjectHandle {.importcpp: "#.getEmbeddedFileStream()".}

{.pop.}

# QPDFEmbeddedFileDocumentHelper class

{.push header: "<qpdf/QPDFEmbeddedFileDocumentHelper.hh>".}

type
  QPDFEmbeddedFileDocumentHelper* {.importcpp: "QPDFEmbeddedFileDocumentHelper".} = object

  EmbeddedFileMap* = StdMap[StdString, SharedPtr[QPDFFileSpecObjectHelper]]

proc initQPDFEmbeddedFileDocumentHelper*(
  qpdf: var QPDF
): QPDFEmbeddedFileDocumentHelper {.
  importcpp: "QPDFEmbeddedFileDocumentHelper(@)", constructor
.}

proc hasEmbeddedFiles*(
  h: QPDFEmbeddedFileDocumentHelper
): bool {.importcpp: "#.hasEmbeddedFiles()".}

proc getEmbeddedFiles*(
  h: var QPDFEmbeddedFileDocumentHelper
): EmbeddedFileMap {.importcpp: "#.getEmbeddedFiles()".}

proc replaceEmbeddedFile*(
  h: var QPDFEmbeddedFileDocumentHelper, name: StdString, fs: QPDFFileSpecObjectHelper
) {.importcpp: "#.replaceEmbeddedFile(@)".}

proc removeEmbeddedFile*(
  h: var QPDFEmbeddedFileDocumentHelper, name: StdString
): bool {.importcpp: "#.removeEmbeddedFile(@)".}

{.pop.}

# QPDFOutlineDocumentHelper class

{.push header: "<qpdf/QPDFOutlineDocumentHelper.hh>".}

type QPDFOutlineDocumentHelper* {.importcpp: "QPDFOutlineDocumentHelper".} = object

proc initQPDFOutlineDocumentHelper*(
  qpdf: var QPDF
): QPDFOutlineDocumentHelper {.importcpp: "QPDFOutlineDocumentHelper(@)", constructor.}

proc hasOutlines*(h: QPDFOutlineDocumentHelper): bool {.importcpp: "#.hasOutlines()".}

{.pop.}

# QPDFOutlineObjectHelper class

{.push header: "<qpdf/QPDFOutlineObjectHelper.hh>".}

type QPDFOutlineObjectHelper* {.importcpp: "QPDFOutlineObjectHelper".} = object

proc initQPDFOutlineObjectHelper*(
  oh: QPDFObjectHandle
): QPDFOutlineObjectHelper {.importcpp: "QPDFOutlineObjectHelper(@)", constructor.}

proc getObjectHandle*(
  h: QPDFOutlineObjectHelper
): QPDFObjectHandle {.importcpp: "#.getObjectHandle()".}

proc getTitle*(h: QPDFOutlineObjectHelper): StdString {.importcpp: "#.getTitle()".}
proc getDest*(h: QPDFOutlineObjectHelper): QPDFObjectHandle {.importcpp: "#.getDest()".}
proc getCount*(h: QPDFOutlineObjectHelper): cint {.importcpp: "#.getCount()".}
proc getKids*(
  h: var QPDFOutlineObjectHelper
): StdVector[QPDFOutlineObjectHelper] {.importcpp: "#.getKids()".}

{.pop.}

# QPDFAcroFormDocumentHelper class

{.push header: "<qpdf/QPDFAcroFormDocumentHelper.hh>".}

type QPDFAcroFormDocumentHelper* {.importcpp: "QPDFAcroFormDocumentHelper".} = object

proc initQPDFAcroFormDocumentHelper*(
  qpdf: var QPDF
): QPDFAcroFormDocumentHelper {.
  importcpp: "QPDFAcroFormDocumentHelper(@)", constructor
.}

proc hasAcroForm*(h: QPDFAcroFormDocumentHelper): bool {.importcpp: "#.hasAcroForm()".}
proc generateAppearancesIfNeeded*(
  h: var QPDFAcroFormDocumentHelper
) {.importcpp: "#.generateAppearancesIfNeeded()".}

{.pop.}

# QPDFFormFieldObjectHelper class

{.push header: "<qpdf/QPDFFormFieldObjectHelper.hh>".}

type QPDFFormFieldObjectHelper* {.importcpp: "QPDFFormFieldObjectHelper".} = object

proc initQPDFFormFieldObjectHelper*(
  oh: QPDFObjectHandle
): QPDFFormFieldObjectHelper {.importcpp: "QPDFFormFieldObjectHelper(@)", constructor.}

proc getObjectHandle*(
  h: QPDFFormFieldObjectHelper
): QPDFObjectHandle {.importcpp: "#.getObjectHandle()".}

proc getFieldType*(
  h: QPDFFormFieldObjectHelper
): StdString {.importcpp: "#.getFieldType()".}

proc getFullyQualifiedName*(
  h: QPDFFormFieldObjectHelper
): StdString {.importcpp: "#.getFullyQualifiedName()".}

proc getPartialName*(
  h: QPDFFormFieldObjectHelper
): StdString {.importcpp: "#.getPartialName()".}

proc getValue*(
  h: QPDFFormFieldObjectHelper
): QPDFObjectHandle {.importcpp: "#.getValue()".}

proc getDefaultValue*(
  h: QPDFFormFieldObjectHelper
): QPDFObjectHandle {.importcpp: "#.getDefaultValue()".}

proc isReadOnly*(h: QPDFFormFieldObjectHelper): bool {.importcpp: "#.isReadOnly()".}
proc isRequired*(h: QPDFFormFieldObjectHelper): bool {.importcpp: "#.isRequired()".}

{.pop.}

# QPDFAnnotationObjectHelper class

{.push header: "<qpdf/QPDFAnnotationObjectHelper.hh>".}

type QPDFAnnotationObjectHelper* {.importcpp: "QPDFAnnotationObjectHelper".} = object

proc initQPDFAnnotationObjectHelper*(
  oh: QPDFObjectHandle
): QPDFAnnotationObjectHelper {.
  importcpp: "QPDFAnnotationObjectHelper(@)", constructor
.}

proc getObjectHandle*(
  h: QPDFAnnotationObjectHelper
): QPDFObjectHandle {.importcpp: "#.getObjectHandle()".}

proc getSubtype*(
  h: QPDFAnnotationObjectHelper
): StdString {.importcpp: "#.getSubtype()".}

proc getRect*(h: QPDFAnnotationObjectHelper): Rectangle {.importcpp: "#.getRect()".}
proc getAppearanceStream*(
  h: QPDFAnnotationObjectHelper, which: StdString, state: StdString = initStdString()
): QPDFObjectHandle {.importcpp: "#.getAppearanceStream(@)".}

proc getAppearanceDictionary*(
  h: QPDFAnnotationObjectHelper
): QPDFObjectHandle {.importcpp: "#.getAppearanceDictionary()".}

proc getFlags*(h: QPDFAnnotationObjectHelper): cint {.importcpp: "#.getFlags()".}

{.pop.}

# QUtil functions

{.push header: "<qpdf/QUtil.hh>".}

type QPDFTime* {.importcpp: "QUtil::QPDFTime".} = object
  year*: cint
  month*: cint
  day*: cint
  hour*: cint
  minute*: cint
  second*: cint
  tz_delta*: cint

proc initQPDFTime*(
  year, month, day, hour, minute, second, tz_delta: cint
): QPDFTime {.importcpp: "QUtil::QPDFTime(@)", constructor.}

proc qpdf_time_to_pdf_time*(
  t: QPDFTime
): StdString {.importcpp: "QUtil::qpdf_time_to_pdf_time(@)".}

{.pop.}

# Convenience wrappers

proc `$`*(oh: QPDFObjectHandle): string =
  $oh.unparse()

proc `[]`*(oh: QPDFObjectHandle, key: string): QPDFObjectHandle =
  oh.getKey(toStdString(key))

proc `[]`*(oh: QPDFObjectHandle, idx: int): QPDFObjectHandle =
  oh.getArrayItem(idx.cint)

proc `[]=`*(oh: var QPDFObjectHandle, key: string, val: QPDFObjectHandle) =
  oh.replaceKey(toStdString(key), val)

proc contains*(oh: QPDFObjectHandle, key: string): bool =
  oh.hasKey(toStdString(key))

proc len*(oh: QPDFObjectHandle): int =
  if oh.isArray():
    oh.getArrayNItems().int
  else:
    0

iterator items*(oh: QPDFObjectHandle): QPDFObjectHandle =
  if oh.isArray():
    for i in 0 ..< oh.getArrayNItems():
      yield oh.getArrayItem(i)
