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
               id: user_external.id,
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

  describe "get_user_by_username/1" do
    test "returns user when username exists" do
      user = insert(:user)

      assert {:ok, %UserExternal{} = user_external} =
               UserService.get_user_by_username(user.username)

      assert user_external.username == user.username
      assert user_external.email == user.email
      assert user_external.id == user.id
    end

    test "returns error when username does not exist" do
      assert {:error, :not_found} = UserService.get_user_by_username("nonexistent")
    end
  end

  describe "get_user_by_email/1" do
    test "returns user when email exists" do
      user = insert(:user)
      assert {:ok, %UserExternal{} = user_external} = UserService.get_user_by_email(user.email)
      assert user_external.email == user.email
      assert user_external.username == user.username
      assert user_external.id == user.id
    end

    test "returns error when email does not exist" do
      assert {:error, :not_found} = UserService.get_user_by_email("notfound@email.com")
    end
  end
end
