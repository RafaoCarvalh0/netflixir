defmodule Netflixir.Users.Services.UserServiceTest do
  use Netflixir.DataCase, async: true
  import Netflixir.Factory

  alias Netflixir.Users.Services.UserService
  alias Netflixir.Users.Externals.UserExternal

  describe "register_user/1" do
    test "creates a valid user" do
      attrs = params_for(:user, password: "supersecret")
      assert {:ok, %UserExternal{} = user_external} = UserService.register_user(attrs)

      assert user_external == %UserExternal{
               name: attrs.name,
               email: attrs.email,
               username: attrs.username,
               created_at: user_external.created_at,
               updated_at: user_external.updated_at
             }
    end

    test "returns error if required fields are missing" do
      attrs = %{email: "", username: "", password: ""}
      assert {:error, changeset} = UserService.register_user(attrs)
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :name)
      assert Map.has_key?(errors, :email)
      assert Map.has_key?(errors, :username)
      assert Map.has_key?(errors, :password)
    end
  end

  describe "login_user/1" do
    test "authenticates with correct username and password" do
      user = insert(:user, password: "mypassword")

      assert {:ok, %UserExternal{} = user_external} =
               UserService.login_user(%{username: user.username, password: "mypassword"})

      assert user_external == %UserExternal{
               name: user.name,
               email: user.email,
               username: user.username,
               created_at: user_external.created_at,
               updated_at: user_external.updated_at
             }
    end

    test "authenticates with correct email and password" do
      user = insert(:user, password: "mypassword")

      assert {:ok, %UserExternal{} = user_external} =
               UserService.login_user(%{email: user.email, password: "mypassword"})

      assert user_external == %UserExternal{
               name: user.name,
               email: user.email,
               username: user.username,
               created_at: user_external.created_at,
               updated_at: user_external.updated_at
             }
    end

    test "returns error if user does not exist" do
      assert {:error, :not_found} =
               UserService.login_user(%{username: "nonexistent", password: "123"})
    end

    test "returns error if password is incorrect" do
      user = insert(:user, password: "mypassword")

      assert {:error, :invalid_password} =
               UserService.login_user(%{username: user.username, password: "wrongpass"})
    end
  end
end
