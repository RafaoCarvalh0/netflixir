defmodule NetflixirWeb.Auth.Token do
  use Joken.Config

  @one_day_in_seconds 24 * 60 * 60

  @spec token_config() :: Joken.config()
  def token_config do
    default_claims(
      iss: "netflixir",
      aud: "netflixir",
      default_ttl: @one_day_in_seconds
    )
  end

  @spec generate_token(%{id: non_neg_integer(), username: String.t()}) ::
          {:ok, String.t()} | {:error, any()}
  def generate_token(user) do
    extra_claims = %{
      "sub" => user.id,
      "username" => user.username,
      "iat" => DateTime.utc_now() |> DateTime.to_unix(),
      "exp" =>
        DateTime.utc_now() |> DateTime.add(@one_day_in_seconds, :second) |> DateTime.to_unix()
    }

    {:ok, token, _claims} = generate_and_sign(extra_claims)
    {:ok, token}
  end

  @spec verify_token(String.t()) :: {:ok, map()} | {:error, any()}
  def verify_token(token) do
    case verify_and_validate(token) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end
end
