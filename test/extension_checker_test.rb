# frozen_string_literal: true

require 'test_helper'

class ExtensionCheckerTest < Minitest::Test
  def setup
    PgaiRails::ExtensionChecker.reset_cache!
  end

  def teardown
    PgaiRails::ExtensionChecker.reset_cache!
  end

  context '#pgai_available?' do
    should 'return true when pgai extension is available' do
      mock_connection = mock
      mock_connection.expects(:execute)
        .with("SELECT 1 FROM pg_extension WHERE extname = 'ai'")
        .returns([{ 'exists' => '1' }])
      ActiveRecord::Base.stubs(:connection).returns(mock_connection)

      assert_predicate PgaiRails::ExtensionChecker, :pgai_available?
    end

    should 'return false when pgai extension is not available' do
      mock_connection = mock
      mock_connection.expects(:execute)
        .with("SELECT 1 FROM pg_extension WHERE extname = 'ai'")
        .returns([])
      ActiveRecord::Base.stubs(:connection).returns(mock_connection)

      assert_not PgaiRails::ExtensionChecker.pgai_available?
    end

    should 'return false when database query fails' do
      ActiveRecord::Base.stubs(:connection).raises(StandardError, 'Connection failed')

      assert_not PgaiRails::ExtensionChecker.pgai_available?
    end

    should 'cache the result' do
      mock_connection = mock
      mock_connection.expects(:execute).once.returns([{ 'exists' => '1' }])
      ActiveRecord::Base.stubs(:connection).returns(mock_connection)

      # Call twice, but expect only one database call
      assert_predicate PgaiRails::ExtensionChecker, :pgai_available?
      assert_predicate PgaiRails::ExtensionChecker, :pgai_available?
    end
  end

  context '#pgvector_available?' do
    should 'return true when pgvector extension is available' do
      mock_connection = mock
      mock_connection.expects(:execute)
        .with("SELECT 1 FROM pg_extension WHERE extname = 'vector'")
        .returns([{ 'exists' => '1' }])
      ActiveRecord::Base.stubs(:connection).returns(mock_connection)

      assert_predicate PgaiRails::ExtensionChecker, :pgvector_available?
    end

    should 'return false when pgvector extension is not available' do
      mock_connection = mock
      mock_connection.expects(:execute)
        .with("SELECT 1 FROM pg_extension WHERE extname = 'vector'")
        .returns([])
      ActiveRecord::Base.stubs(:connection).returns(mock_connection)

      assert_not PgaiRails::ExtensionChecker.pgvector_available?
    end
  end

  context '#reset_cache!' do
    should 'clear cached results' do
      # Set up initial cache
      mock_connection = mock
      mock_connection.expects(:execute).twice.returns([{ 'exists' => '1' }])
      ActiveRecord::Base.stubs(:connection).returns(mock_connection)

      assert_predicate PgaiRails::ExtensionChecker, :pgai_available?

      # Reset cache
      PgaiRails::ExtensionChecker.reset_cache!

      # Should make another database call
      assert_predicate PgaiRails::ExtensionChecker, :pgai_available?
    end
  end
end
