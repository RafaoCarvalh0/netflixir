defmodule Netflixir.Users.Externals.UserExternal do
  @moduledoc false

  @derive {Jason.Encoder, only: [:id, :name, :email, :username, :created_at, :updated_at]}
  defstruct [:id, :name, :email, :username, :created_at, :updated_at]

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          name: String.t(),
          email: String.t(),
          username: String.t(),
          created_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @type user_attrs :: %{
          id: non_neg_integer(),
          name: String.t(),
          email: String.t(),
          username: String.t(),
          created_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @spec from_db(user_attrs()) :: t()
  def from_db(attrs) do
    %__MODULE__{
      id: attrs.id,
      name: attrs.name,
      email: attrs.email,
      username: attrs.username,
      created_at: attrs.created_at,
      updated_at: attrs.updated_at
    }
  end
end
