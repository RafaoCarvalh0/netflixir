defmodule Netflixir.Users.Inputs.UserInputs do
  @type register_user_input :: %{
          required(:name) => String.t(),
          required(:email) => String.t(),
          required(:username) => String.t(),
          required(:password) => String.t()
        }

  @type login_user_input :: %{
          required(:password) => String.t(),
          optional(:username) => String.t(),
          optional(:email) => String.t()
        }
end
