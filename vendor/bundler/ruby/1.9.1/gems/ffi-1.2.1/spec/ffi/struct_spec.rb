#
# This file is part of ruby-ffi.
#
# This code is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License version 3 only, as
# published by the Free Software Foundation.
#
# This code is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
# version 3 for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# version 3 along with this work.  If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))
describe "Struct tests" do
  StructTypes = {
    's8' => :char,
    's16' => :short,
    's32' => :int,
    's64' => :long_long,
    'long' => :long,
    'f32' => :float,
    'f64' => :double
  }
  module LibTest
    extend FFI::Library
    ffi_lib TestLibrary::PATH
    attach_function :ptr_ret_pointer, [ :pointer, :int], :string
    attach_function :ptr_ret_int32_t, [ :pointer, :int ], :int
    attach_function :ptr_from_address, [ :ulong ], :pointer
    attach_function :string_equals, [ :string, :string ], :int
    [ 's8', 's16', 's32', 's64', 'f32', 'f64', 'long' ].each do |t|
      attach_function "struct_align_#{t}", [ :pointer ], StructTypes[t]
    end
  end
  class PointerMember < FFI::Struct
    layout :pointer, :pointer
  end
  class StringMember < FFI::Struct
    layout :string, :string
  end
  it "Struct#[:pointer]" do
    magic = 0x12345678
    mp = FFI::MemoryPointer.new :long
    mp.put_long(0, magic)
    smp = FFI::MemoryPointer.new :pointer
    smp.put_pointer(0, mp)
    s = PointerMember.new smp
    s[:pointer].should eq mp
  end
  it "Struct#[:pointer].nil? for NULL value" do
    magic = 0x12345678
    mp = FFI::MemoryPointer.new :long
    mp.put_long(0, magic)
    smp = FFI::MemoryPointer.new :pointer
    smp.put_pointer(0, nil)
    s = PointerMember.new smp
    s[:pointer].null?.should eq true
  end
  it "Struct#[:pointer]=" do
    magic = 0x12345678
    mp = FFI::MemoryPointer.new :long
    mp.put_long(0, magic)
    smp = FFI::MemoryPointer.new :pointer
    s = PointerMember.new smp
    s[:pointer] = mp
    smp.get_pointer(0).should eq mp
  end
  it "Struct#[:pointer]=struct" do
    smp = FFI::MemoryPointer.new :pointer
    s = PointerMember.new smp
    lambda { s[:pointer] = s }.should_not raise_error
  end
  it "Struct#[:pointer]=nil" do
    smp = FFI::MemoryPointer.new :pointer
    s = PointerMember.new smp
    s[:pointer] = nil
    smp.get_pointer(0).null?.should eq true
  end
  it "Struct#[:string]" do
    magic = "test"
    mp = FFI::MemoryPointer.new 1024
    mp.put_string(0, magic)
    smp = FFI::MemoryPointer.new :pointer
    smp.put_pointer(0, mp)
    s = StringMember.new smp
    s[:string].should eq magic
  end
  it "Struct#[:string].nil? for NULL value" do
    smp = FFI::MemoryPointer.new :pointer
    smp.put_pointer(0, nil)
    s = StringMember.new smp
    s[:string].nil?.should eq true
  end
  it "Struct#layout works with :name, :type pairs" do
    class PairLayout < FFI::Struct
      layout :a, :int, :b, :long_long
    end
    ll_off = (FFI::TYPE_UINT64.alignment == 4 ? 4 : 8)
    PairLayout.size.should eq(ll_off + 8)
    mp = FFI::MemoryPointer.new(PairLayout.size)
    s = PairLayout.new mp
    s[:a] = 0x12345678
    mp.get_int(0).should eq 0x12345678
    s[:b] = 0xfee1deadbeef
    mp.get_int64(ll_off).should eq 0xfee1deadbeef
  end
  it "Struct#layout works with :name, :type, offset tuples" do
    class PairLayout < FFI::Struct
      layout :a, :int, 0, :b, :long_long, 4
    end
    PairLayout.size.should eq(FFI::TYPE_UINT64.alignment == 4 ? 12 : 16)
    mp = FFI::MemoryPointer.new(PairLayout.size)
    s = PairLayout.new mp
    s[:a] = 0x12345678
    mp.get_int(0).should eq 0x12345678
    s[:b] = 0xfee1deadbeef
    mp.get_int64(4).should eq 0xfee1deadbeef
  end
  it "Struct#layout works with mixed :name,:type and :name,:type,offset" do
    class MixedLayout < FFI::Struct
      layout :a, :int, :b, :long_long, 4
    end
    MixedLayout.size.should eq(FFI::TYPE_UINT64.alignment == 4 ? 12 : 16)
    mp = FFI::MemoryPointer.new(MixedLayout.size)
    s = MixedLayout.new mp
    s[:a] = 0x12345678
    mp.get_int(0).should eq 0x12345678
    s[:b] = 0xfee1deadbeef
    mp.get_int64(4).should eq 0xfee1deadbeef
  end
  rb_maj, rb_min = RUBY_VERSION.split('.')
  if rb_maj.to_i >= 1 && rb_min.to_i >= 9 || RUBY_PLATFORM =~ /java/
    it "Struct#layout withs with a hash of :name => type" do
      class HashLayout < FFI::Struct
        layout :a => :int, :b => :long_long
      end
      ll_off = (FFI::TYPE_UINT64.alignment == 4? 4 : 8)
      HashLayout.size.should eq(ll_off + 8)
      mp = FFI::MemoryPointer.new(HashLayout.size)
      s = HashLayout.new mp
      s[:a] = 0x12345678
      mp.get_int(0).should eq 0x12345678
      s[:b] = 0xfee1deadbeef
      mp.get_int64(ll_off).should eq 0xfee1deadbeef
      end
  end

  it "subclass overrides initialize without calling super" do
    class InitializeWithoutSuper < FFI::Struct
      layout :a, :int, :b, :long_long, :d, [:double, 2]

      def initialize(a, b)
        self[:a] = a
        self[:b] = b
        self[:d][0] = 1.2
        self[:d][1] = 3.4
      end

    end
    s = InitializeWithoutSuper.new(0x1eefbeef, 0xdeadcafebabe)
    s[:a].should eq 0x1eefbeef
    s[:b].should eq 0xdeadcafebabe
  end

  it "Can use Struct subclass as parameter type" do
    module StructParam
      extend FFI::Library
      ffi_lib TestLibrary::PATH
      class TestStruct < FFI::Struct
        layout :c, :char
      end
      attach_function :struct_field_s8, [ TestStruct.in ], :char
    end
  end
  it "Can use Struct subclass as IN parameter type" do
    module StructParam2
      extend FFI::Library
      ffi_lib TestLibrary::PATH
      class TestStruct < FFI::Struct
        layout :c, :char
      end
      attach_function :struct_field_s8, [ TestStruct.in ], :char
    end
  end
  it "Can use Struct subclass as OUT parameter type" do
    module StructParam3
      extend FFI::Library
      ffi_lib TestLibrary::PATH
      class TestStruct < FFI::Struct
        layout :c, :char
      end
      attach_function :struct_field_s8, [ TestStruct.out ], :char
    end
  end
  it "can be passed directly as a :pointer parameter" do
    class TestStruct < FFI::Struct
      layout :i, :int
    end
    s = TestStruct.new
    s[:i] = 0x12
    LibTest.ptr_ret_int32_t(s, 0).should eq 0x12
  end
  it ":char member aligned correctly" do
    class AlignChar < FFI::Struct
      layout :c, :char, :v, :char
    end
    s = AlignChar.new
    s[:v] = 0x12
    LibTest.struct_align_s8(s.pointer).should eq 0x12
  end
  it ":short member aligned correctly" do
    class AlignShort < FFI::Struct
      layout :c, :char, :v, :short
    end
    s = AlignShort.alloc_in
    s[:v] = 0x1234
    LibTest.struct_align_s16(s.pointer).should eq 0x1234
  end
  it ":int member aligned correctly" do
    class AlignInt < FFI::Struct
      layout :c, :char, :v, :int
    end
    s = AlignInt.alloc_in
    s[:v] = 0x12345678
    LibTest.struct_align_s32(s.pointer).should eq 0x12345678
  end
  it ":long_long member aligned correctly" do
    class AlignLongLong < FFI::Struct
      layout :c, :char, :v, :long_long
    end
    s = AlignLongLong.alloc_in
    s[:v] = 0x123456789abcdef0
    LibTest.struct_align_s64(s.pointer).should eq 0x123456789abcdef0
  end
  it ":long member aligned correctly" do
    class AlignLong < FFI::Struct
      layout :c, :char, :v, :long
    end
    s = AlignLong.alloc_in
    s[:v] = 0x12345678
    LibTest.struct_align_long(s.pointer).should eq 0x12345678
  end
  it ":float member aligned correctly" do
    class AlignFloat < FFI::Struct
      layout :c, :char, :v, :float
    end
    s = AlignFloat.alloc_in
    s[:v] = 1.23456
    (LibTest.struct_align_f32(s.pointer) - 1.23456).abs.should < 0.00001
  end
  it ":double member aligned correctly" do
    class AlignDouble < FFI::Struct
      layout :c, :char, :v, :double
    end
    s = AlignDouble.alloc_in
    s[:v] = 1.23456789
    (LibTest.struct_align_f64(s.pointer) - 1.23456789).abs.should < 0.00000001
  end
  it ":ulong, :pointer struct" do
    class ULPStruct < FFI::Struct
      layout :ul, :ulong, :p, :pointer
    end
    s = ULPStruct.alloc_in
    s[:ul] = 0xdeadbeef
    s[:p] = LibTest.ptr_from_address(0x12345678)
    s.pointer.get_ulong(0).should eq 0xdeadbeef
  end
  def test_num_field(type, v)
    klass = Class.new(FFI::Struct)
    klass.layout :v, type, :dummy, :long
    
    s = klass.new
    s[:v] = v
    s.pointer.send("get_#{type.to_s}", 0).should eq v
    s.pointer.send("put_#{type.to_s}", 0, 0)
    s[:v].should eq 0
  end
  def self.int_field_test(type, values)
    values.each do |v|
      it "#{type} field r/w (#{v.to_s(16)})" do
        test_num_field(type, v)
      end
    end
  end
  int_field_test(:char, [ 0, 127, -128, -1 ])
  int_field_test(:uchar, [ 0, 0x7f, 0x80, 0xff ])
  int_field_test(:short, [ 0, 0x7fff, -0x8000, -1 ])
  int_field_test(:ushort, [ 0, 0x7fff, 0x8000, 0xffff ])
  int_field_test(:int, [ 0, 0x7fffffff, -0x80000000, -1 ])
  int_field_test(:uint, [ 0, 0x7fffffff, 0x80000000, 0xffffffff ])
  int_field_test(:long_long, [ 0, 0x7fffffffffffffff, -0x8000000000000000, -1 ])
  int_field_test(:ulong_long, [ 0, 0x7fffffffffffffff, 0x8000000000000000, 0xffffffffffffffff ])
  if FFI::Platform::LONG_SIZE == 32
    int_field_test(:long, [ 0, 0x7fffffff, -0x80000000, -1 ])
    int_field_test(:ulong, [ 0, 0x7fffffff, 0x80000000, 0xffffffff ])
  else
    int_field_test(:long, [ 0, 0x7fffffffffffffff, -0x8000000000000000, -1 ])
    int_field_test(:ulong, [ 0, 0x7fffffffffffffff, 0x8000000000000000, 0xffffffffffffffff ])
  end
  it ":float field r/w" do
    klass = Class.new(FFI::Struct)
    klass.layout :v, :float, :dummy, :long

    s = klass.new
    value = 1.23456
    s[:v] = value
    (s.pointer.get_float(0) - value).abs.should < 0.0001
  end
  it ":double field r/w" do
    klass = Class.new(FFI::Struct)
    klass.layout :v, :double, :dummy, :long

    s = klass.new
    value = 1.23456
    s[:v] = value
    (s.pointer.get_double(0) - value).abs.should < 0.0001
  end
  module EnumFields
    extend FFI::Library
    TestEnum = enum :test_enum, [:c1, 10, :c2, 20, :c3, 30, :c4, 40]
    class TestStruct < FFI::Struct
      layout :a, :int, :c, :test_enum, 
        :d, [ TestEnum, TestEnum.symbols.length ]
    end
  end
  
  it ":enum field r/w" do
    s = EnumFields::TestStruct.new
    s[:c] = :c3

    s.pointer.get_uint(FFI::Type::INT32.size).should eq 30
    s[:c].should eq :c3
  end
  
  it "array of :enum field" do
    s = EnumFields::TestStruct.new
    EnumFields::TestEnum.symbols.each_with_index do |val, i|
      s[:d][i] = val
    end
    
    EnumFields::TestEnum.symbols.each_with_index do |val, i|
      s.pointer.get_uint(FFI::Type::INT32.size * (2 + i)).should eq EnumFields::TestEnum[val]
    end
    
    s[:d].each_with_index do |val, i|
      val.should eq EnumFields::TestEnum.symbols[i]
    end
  end
  
  module CallbackMember
    extend FFI::Library
    ffi_lib TestLibrary::PATH
    callback :add, [ :int, :int ], :int
    callback :sub, [ :int, :int ], :int
    class TestStruct < FFI::Struct
      layout :add, :add,
        :sub, :sub
    end
    attach_function :struct_call_add_cb, [TestStruct.in, :int, :int], :int
    attach_function :struct_call_sub_cb, [TestStruct.in, :int, :int], :int
  end
  it "Can have CallbackInfo struct field" do
      s = CallbackMember::TestStruct.new
      add_proc = lambda { |a, b| a+b }
      sub_proc = lambda { |a, b| a-b }
      s[:add] = add_proc
      s[:sub] = sub_proc
      CallbackMember.struct_call_add_cb(s, 40, 2).should eq 42
      CallbackMember.struct_call_sub_cb(s, 44, 2).should eq 42
  end
  it "Can return its members as a list" do
    class TestStruct < FFI::Struct
      layout :a, :int, :b, :int, :c, :int
    end
    TestStruct.members.should include(:a, :b, :c)
  end
  it "Can return its instance members and values as lists" do
    class TestStruct < FFI::Struct
      layout :a, :int, :b, :int, :c, :int
    end
    s = TestStruct.new
    s.members.should include(:a, :b, :c)
    s[:a] = 1
    s[:b] = 2
    s[:c] = 3
    s.values.should include(1, 2, 3)
  end
  it 'should return an ordered field/offset pairs array' do
    class TestStruct < FFI::Struct
      layout :a, :int, :b, :int, :c, :int
    end
    s = TestStruct.new
    s.offsets.should eq [[:a, 0], [:b, 4], [:c, 8]]
    TestStruct.offsets.should eq [[:a, 0], [:b, 4], [:c, 8]]
  end
  it "Struct#offset_of returns offset of field within struct" do
    class TestStruct < FFI::Struct
      layout :a, :int, :b, :int, :c, :int
    end
    TestStruct.offset_of(:a).should eq 0
    TestStruct.offset_of(:b).should eq 4
    TestStruct.offset_of(:c).should eq 8
  end
end

describe FFI::Struct, ' with a nested struct field'  do
  module LibTest
    extend FFI::Library
    ffi_lib TestLibrary::PATH
    class NestedStruct < FFI::Struct
      layout :i, :int
    end
    class ContainerStruct < FFI::Struct
      layout :first, :char, :ns, NestedStruct
    end
    attach_function :struct_align_nested_struct, [ :pointer ], :int
    attach_function :struct_make_container_struct, [ :int ], :pointer
  end
  before do
    @cs = LibTest::ContainerStruct.new
  end
  it 'should align correctly nested struct field' do
    @cs[:ns][:i] = 123
    LibTest.struct_align_nested_struct(@cs.to_ptr).should eq 123
  end
  it 'should correctly calculate Container size (in bytes)' do
    LibTest::ContainerStruct.size.should eq 8
  end
  it 'should return a Struct object when the field is accessed' do
    @cs[:ns].is_a?(FFI::Struct).should be_true 
  end
  it 'should read a value from memory' do
    @cs = LibTest::ContainerStruct.new(LibTest.struct_make_container_struct(123))
    @cs[:ns][:i].should eq 123
  end
  it 'should write a value to memory' do
    @cs = LibTest::ContainerStruct.new(LibTest.struct_make_container_struct(123))
    @cs[:ns][:i] = 456
    LibTest.struct_align_nested_struct(@cs.to_ptr).should eq 456
  end

  it 'should be able to assign struct instance to nested field' do 
    cs = LibTest::ContainerStruct.new(LibTest.struct_make_container_struct(123))
    ns = LibTest::NestedStruct.new
    ns[:i] = 567
    cs[:ns] = ns
    cs[:ns][:i].should eq 567
    LibTest.struct_align_nested_struct(cs.to_ptr).should eq 567
  end
end

describe FFI::Struct, ' with a nested array of structs'  do
  module InlineArrayOfStructs
    extend FFI::Library
    ffi_lib TestLibrary::PATH
    class NestedStruct < FFI::Struct
      layout :i, :int
    end
    class ContainerStruct < FFI::Struct
      layout :first, :char, :ns, [ NestedStruct, 1 ]
    end
    attach_function :struct_align_nested_struct, [ :pointer ], :int
    attach_function :struct_make_container_struct, [ :int ], :pointer
  end

  before do
    @cs = InlineArrayOfStructs::ContainerStruct.new
  end

  it 'should align correctly nested struct field' do
    @cs[:ns][0][:i] = 123
    InlineArrayOfStructs.struct_align_nested_struct(@cs.to_ptr).should eq 123
  end

  it 'should correctly calculate Container size (in bytes)' do
    InlineArrayOfStructs::ContainerStruct.size.should eq 8
  end

  it 'should return a Struct object when the field is accessed' do
    @cs[:ns][0].is_a?(FFI::Struct).should be_true
  end

  it 'should read a value from memory' do
    @cs = InlineArrayOfStructs::ContainerStruct.new(InlineArrayOfStructs.struct_make_container_struct(123))
    @cs[:ns][0][:i].should eq 123
  end

  it 'should write a value to memory' do
    @cs = InlineArrayOfStructs::ContainerStruct.new(InlineArrayOfStructs.struct_make_container_struct(123))
    @cs[:ns][0][:i] = 456
    InlineArrayOfStructs.struct_align_nested_struct(@cs.to_ptr).should eq 456
  end

  it 'should support Enumerable#each' do
    @cs = InlineArrayOfStructs::ContainerStruct.new(InlineArrayOfStructs.struct_make_container_struct(123))
    ints = []
    @cs[:ns].each { |s| ints << s[:i] }
    ints[0].should eq 123
  end
end

describe FFI::Struct, ' by value'  do
  module LibTest
    extend FFI::Library
    ffi_lib TestLibrary::PATH

    class S8S32 < FFI::Struct
      layout :s8, :char, :s32, :int
    end

    class StructString < FFI::Struct
      layout :bytes, :string, :len, :int
    end

    attach_function :struct_return_s8s32, [ ], S8S32.by_value
    attach_function :struct_s8s32_set, [ :char, :int ], S8S32.by_value
    attach_function :struct_s8s32_get_s8, [ S8S32.by_value ], :char
    attach_function :struct_s8s32_get_s32, [ S8S32.by_value ], :int
    attach_function :struct_s8s32_s32_ret_s32, [ S8S32.by_value, :int ], :int
    attach_function :struct_s8s32_s64_ret_s64, [ S8S32.by_value, :long_long ], :long_long
    attach_function :struct_s8s32_ret_s8s32, [ S8S32.by_value ], S8S32.by_value
    attach_function :struct_s32_ptr_s32_s8s32_ret_s32, [ :int, :pointer, :int, S8S32.by_value ], :int
    attach_function :struct_varargs_ret_struct_string, [ :int, :varargs ], StructString.by_value
  end

  it 'return using pre-set values' do
    s = LibTest.struct_return_s8s32
    s[:s8].should eq 0x7f
    s[:s32].should eq 0x12345678
  end

  it 'return using passed in values' do
    s = LibTest.struct_s8s32_set(123, 456789)
    s[:s8].should eq 123
    s[:s32].should eq 456789
  end

  it 'parameter' do
    s = LibTest::S8S32.new
    s[:s8] = 0x12
    s[:s32] = 0x34567890
    LibTest.struct_s8s32_get_s8(s).should eq 0x12
    LibTest.struct_s8s32_get_s32(s).should eq 0x34567890
  end

  it 'parameter with following s32' do
    s = LibTest::S8S32.new
    s[:s8] = 0x12
    s[:s32] = 0x34567890
    
    LibTest.struct_s8s32_s32_ret_s32(s, 0x1eefdead).should eq 0x1eefdead
  end

  it 'parameter with following s64' do
    s = LibTest::S8S32.new
    s[:s8] = 0x12
    s[:s32] = 0x34567890
  end

  it 'parameter with preceding s32,ptr,s32' do
    s = LibTest::S8S32.new
    s[:s8] = 0x12
    s[:s32] = 0x34567890
    out = LibTest::S8S32.new
    LibTest.struct_s32_ptr_s32_s8s32_ret_s32(0x1000000, out, 0x1eafbeef, s).should eq 0x34567890
    out[:s8].should eq s[:s8]
    out[:s32].should eq s[:s32]
  end

  it 'parameter with preceding s32,string,s32' do
    s = LibTest::S8S32.new
    s[:s8] = 0x12
    s[:s32] = 0x34567890
    out = 0.chr * 32
    LibTest.struct_s32_ptr_s32_s8s32_ret_s32(0x1000000, out, 0x1eafbeef, s).should eq 0x34567890
  end

  it 'parameter, returning struct by value' do
    s = LibTest::S8S32.new
    s[:s8] = 0x12
    s[:s32] = 0x34567890

    ret = LibTest.struct_s8s32_ret_s8s32(s)
    ret[:s8].should eq s[:s8]
    ret[:s32].should eq s[:s32]
  end

  it 'varargs returning a struct' do
    string = "test"
    s = LibTest.struct_varargs_ret_struct_string(4, :string, string)
    s[:len].should eq string.length
    s[:bytes].should eq string
  end
end

describe FFI::Struct, ' with an array field'  do
  module LibTest
    extend FFI::Library
    ffi_lib TestLibrary::PATH
    class StructWithArray < FFI::Struct
      layout :first, :char, :a, [:int, 5]
    end
    attach_function :struct_make_struct_with_array, [:int, :int, :int, :int, :int], :pointer
    attach_function :struct_field_array, [:pointer], :pointer
  end
  before do
    @s = LibTest::StructWithArray.new
  end
  it 'should correctly calculate StructWithArray size (in bytes)' do
    LibTest::StructWithArray.size.should eq 24
  end
  it 'should read values from memory' do
    @s = LibTest::StructWithArray.new(LibTest.struct_make_struct_with_array(0, 1, 2, 3, 4))
    @s[:a].to_a.should eq [0, 1, 2, 3, 4]
  end
#  it 'should cache array object for successive calls' do
#    @s[:a].object_id.should eq @s[:a].object_id
#  end
  it 'should return the number of elements in the array field' do
    @s = LibTest::StructWithArray.new(LibTest.struct_make_struct_with_array(0, 1, 2, 3, 4))
    @s[:a].size.should eq 5
  end
  it 'should allow iteration through the array elements' do
    @s = LibTest::StructWithArray.new(LibTest.struct_make_struct_with_array(0, 1, 2, 3, 4))
    @s[:a].each_with_index { |elem, i| elem.should eq i }  
  end
  it 'should return the pointer to the array' do
    @s = LibTest::StructWithArray.new(LibTest.struct_make_struct_with_array(0, 1, 2, 3, 4))
    @s[:a].to_ptr.should eq LibTest::struct_field_array(@s.to_ptr)
  end
end

describe 'BuggedStruct' do
  module LibTest
    extend FFI::Library
    ffi_lib TestLibrary::PATH
    class BuggedStruct < FFI::Struct
      layout :visible, :uchar,
              :x, :uint,
              :y, :uint,
              :rx, :short,
              :ry, :short,
              :order, :uchar,
              :size, :uchar
    end
    attach_function :bugged_struct_size, [], :uint
  end
  it 'should return its correct size' do
    LibTest::BuggedStruct.size.should eq LibTest.bugged_struct_size
  end
  it "offsets within struct should be correct" do
    LibTest::BuggedStruct.offset_of(:visible).should eq 0
    LibTest::BuggedStruct.offset_of(:x).should eq 4
    LibTest::BuggedStruct.offset_of(:y).should eq 8
    LibTest::BuggedStruct.offset_of(:rx).should eq 12
    LibTest::BuggedStruct.offset_of(:ry).should eq 14
    LibTest::BuggedStruct.offset_of(:order).should eq 16
    LibTest::BuggedStruct.offset_of(:size).should eq 17
  end
  it 'should return correct field/offset pairs' do
    LibTest::BuggedStruct.offsets.sort do |a, b|
      a[1] <=> b[1] 
    end.should eq [[:visible, 0], [:x, 4], [:y, 8], [:rx, 12], [:ry, 14], [:order, 16], [:size, 17]]
  end
end

describe "Struct allocation" do
  it "MemoryPointer.new(Struct, 2)" do
    class S < FFI::Struct
      layout :i, :uint
    end
    p = FFI::MemoryPointer.new(S, 2)
    p.total.should eq 8
    p.type_size.should eq 4
    p.put_uint(4, 0xdeadbeef)
    S.new(p[1])[:i].should eq 0xdeadbeef
    p[1].address.should eq(p[0].address + 4)
  end

  it "Buffer.new(Struct, 2)" do
    class S < FFI::Struct
      layout :i, :uint
    end
    p = FFI::Buffer.new(S, 2)
    p.total.should eq 8
    p.type_size.should eq 4
    p.put_uint(4, 0xdeadbeef)
    S.new(p[1])[:i].should eq 0xdeadbeef
  end

  it "null? should be true when initialized with NULL pointer" do
    class S < FFI::Struct
      layout :i, :uint
    end
    S.new(FFI::Pointer::NULL).null?.should be_true
  end

  it "null? should be false when initialized with non-NULL pointer" do
    class S < FFI::Struct
      layout :i, :uint
    end
    S.new(FFI::MemoryPointer.new(S)).null?.should be_false
  end

  it "supports :bool as a struct member" do
    lambda do
      c = Class.new(FFI::Struct) do
        layout :b, :bool
      end
      struct = c.new
      struct[:b] = ! struct[:b]
    end.should_not raise_error
  end

end

describe "variable-length arrays" do
  it "zero length array should be accepted as last field" do
    lambda {
      Class.new(FFI::Struct) do
        layout :count, :int, :data, [ :char, 0 ]
      end
    }.should_not raise_error
  end

  it "zero length array before last element should raise error" do
    lambda {
      Class.new(FFI::Struct) do
        layout :data, [ :char, 0 ], :count, :int
      end
    }.should raise_error
  end

  it "can access elements of array" do
    struct_class = Class.new(FFI::Struct) do
      layout :count, :int, :data, [ :long, 0 ]
    end
    s = struct_class.new(FFI::MemoryPointer.new(1024))
    s[:data][0] = 0x1eadbeef
    s[:data][1] = 0x12345678
    s[:data][0].should eq 0x1eadbeef
    s[:data][1].should eq 0x12345678
  end

  it "non-variable length array is bounds checked" do
    struct_class = Class.new(FFI::Struct) do
      layout :count, :int, :data, [ :long, 1 ]
    end
    s = struct_class.new(FFI::MemoryPointer.new(1024))
    s[:data][0] = 0x1eadbeef
    lambda { s[:data][1] = 0x12345678 }.should raise_error
    s[:data][0].should eq 0x1eadbeef
    lambda { s[:data][1].should eq 0x12345678 }.should raise_error
  end
end
