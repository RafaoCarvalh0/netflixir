defmodule Netflixir.Test.Mocks do
  @moduledoc """
  Defines Mox mocks for testing.
  """

  Mox.defmock(Netflixir.Storage.Mock, for: Netflixir.Storage)
end
