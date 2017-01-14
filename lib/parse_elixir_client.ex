defmodule ParseClient do
  @moduledoc """
  REST API client for Parse in Elixir

  ## Example usage

  To get information about an object (and print out the whole response):

      ParseClient.get("classes/Lumberjacks")

  To just see the body, use the `query` function:

      ParseClient.query("classes/Lumberjacks")

  To create a new object, use the `post` function, to update an object, use
  the `put` function, and to delete an object, use the `delete` function.

  The `get` and `query` methods can also be used with users and roles.

  ## Use of filters when making queries

  Queries can be filtered by using *filters* and *options*.

  Use filters when you would use `where=` clauses in a request to the Parse API.
  Options include "order", "limit", "count" and "include".

  Both filters and options need to be Elixir maps.

  ## Comparisons in filters

  The following filters (keys) from Parse.com are supported:

  Key | Operation
  --- | ---
  $lt | Less than
  $lte | Less than or equal to
  $gt | Greater than
  $gte | Greater than or equal to
  $ne | Not equal to
  $in | Contained in
  $nin | Not contained in
  $exists | A value is set for the key
  $select | This matches a value for a key in the result of a different query
  $dontSelect | Requires that a key's value not match a value for a key in the result of a different query
  $all | Contains all of the given values

  ### Examples

  To make a query just about animals that are aged less then 3 years old:

      ParseClient.query("classes/Animals", %{"age" => %{"$lt" => 3}})

  To make a query just about animals who have a name and are still alive:

      ParseClient.query("classes/Animals", %{"name" => %{"$exists" => true}, "status" => 1})
  """

  alias ParseClient.Requests, as: Req
  alias ParseClient.Authenticate, as: Auth

  @doc """
  Get request for making queries.
  """
  def get(url), do: Req.request!(:get, url, "", get_headers())

  @doc """
  Get request with filters.

  ## Examples

  To make a query just about animals that have a name and are still alive:

      ParseClient.get("classes/Animals", %{"name" => %{"$exists" => true}, "status" => 1})

  To make a request with options, but no filters, use %{} as the second argument:

      ParseClient.get("classes/Animals", %{}, %{"order" => "createdAt"})
  """
  def get(url, filters, options \\ %{}, httpoison_options \\ []) do
    filter_string = Req.parse_filters(filters, options)
    Req.request!(:get, url <> "?" <> filter_string, "", get_headers(), httpoison_options)
  end

  @doc """
  Get request for making queries. Just returns the body of the response.
  """
  def query(url), do: get(url).body

  @doc """
  Get request for making queries with filters and options.
  Just returns the body of the response.
  """
  def query(url, filters, options \\ %{}) do
    get(url, filters, options).body
  end

  @doc """
  Request to create an object.

  ## Example

      body = %{"animal" => "parrot, "name" => "NorwegianBlue", "status" => 0}
      ParseClient.post("classes/Animals", body)
  """
  def post(url, body, options \\ []), do: Req.request!(:post, url, body, post_headers(), options)

  @doc """
  Request to update an object.

  ## Example

      ParseClient.put("classes/Animals/12345678", %{"status" => 1})
  """
  def put(url, body), do: Req.request!(:put, url, body, post_headers())

  @doc """
  Request to delete an object.

  ## Example

      ParseClient.delete("classes/Animals/12345678")
  """
  def delete(url), do: Req.request!(:delete, url, "", get_headers())

  @doc """
  Request from a user to signup. The user must provide a username
  and a password. The options argument refers to additional information,
  such as email address or phone number, and it needs to be in the form
  of an Elixir map.

  ## Examples

      ParseClient.signup("Duchamp", "L_H;OO#Q")
      ParseClient.signup("Duchamp", "L_H;OO#Q", %{"email" => "eros@selavy.com"})
  """
  def signup(username, password, options \\ %{}) do
    data = Map.merge(%{"username" => username, "password" => password}, options)
    post("users", data).body
  end

  @doc """
  Request from a user to login. Username and password are required.
  As in the signup function, username and password needs to be strings.
  """
  def login(username, password) do
    params = %{"username" => username, "password" => password} |> URI.encode_query
    get("login?#{params}").body
  end

  @doc """
  Request to reset a user's password.

  ## Example

      ParseClient.request_passwd_reset("example@example.com")
  """
  def request_passwd_reset(email) do
    post("requestPasswordReset", %{"email" => email})
  end

  @doc """
  Validates the user. Takes the user's session token as the only argument.

  ## Example

      ParseClient.validate_user("12345678")
  """
  def validate_user(token_val) do
    Req.request!(:get, "users/me", "", post_headers("X-Parse-Session-Token", token_val)).body
  end

  @doc """
  Deletes the user. Takes the user's objectid and session token as arguments.

  ## Example

      ParseClient.delete_user("g7y9tkhB7O", "12345678")
  """
  def delete_user(objectid, token_val) do
    Req.request!(:delete, "users/#{objectid}", "", post_headers("X-Parse-Session-Token", token_val))
  end

  @doc """
  Post request to upload a file.
  """
  def upload_file(url, contents, content_type) do
    Req.request!(:post, url, contents, post_headers("Content-Type", content_type))
  end

  defp get_headers do
    %{"X-Parse-Application-Id" => Auth.config_parse_id,
      "X-Parse-REST-API-Key"   => Auth.config_parse_key}
  end

  defp post_headers(key \\ "Content-Type", val \\ "application/json") do
    Map.put(get_headers(), key, val)
  end
end
