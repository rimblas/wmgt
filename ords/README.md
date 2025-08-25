# ORDS REST API Endpoints

This directory contains Oracle REST Data Services (ORDS) endpoint definitions for the WMGT system.

## Files

- `tournament.sql` - Existing tournament API endpoints for rounds and season data
- `discord_bot_api.sql` - New Discord Bot API endpoints for tournament registration
- `install_discord_api.sql` - Installation script for Discord Bot API
- `test_discord_api.sql` - Test script to validate Discord Bot API functionality

## Installation

### Discord Bot API

To install the Discord Bot API endpoints:

1. Connect to your Oracle database as the WMGT schema owner
2. Run the installation script:
   ```sql
   @install_discord_api.sql
   ```

### Testing

To test the Discord Bot API endpoints:

1. Run the test script:
   ```sql
   @test_discord_api.sql
   ```

2. Test the actual REST endpoints using curl or a REST client:
   ```bash
   # Get current tournament
   curl -X GET "http://your-server/ords/wmgt/api/tournaments/current"
   
   # Get player registrations
   curl -X GET "http://your-server/ords/wmgt/api/players/registrations/123456789"
   ```

## API Documentation

See `../docs/discord_bot_api.md` for complete API documentation including:
- Endpoint specifications
- Request/response formats
- Error codes
- Example usage

## Dependencies

The Discord Bot API endpoints require:
- Oracle Database with ORDS enabled
- WMGT schema with existing tables and packages
- `t_discord_user` package for Discord user synchronization
- Logger package for debugging and monitoring

## Security

### Authenticating

## Obtain a Token

Call `/oauth/token` with your client_id and secret to obtain a token.

```
$ curl -i -d "grant_type=client_credentials" --user "CLIENT_ID:CLIENT_SECRET" http://your-server/ords/wmgt/api/oauth/token
```

In the reponse, the token will be in the `access_token` attribute. Notice the expiration of the token in `expires_in`.


```
HTTP/1.1 200
Date: Sun, 08 Sep 2024 16:36:16 GMT
Content-Type: application/json
Transfer-Encoding: chunked
Connection: keep-alive
Set-Cookie: XXX; Path=/; Secure; HttpOnly
X-Frame-Options: SAMEORIGIN

{"access_token":"NEW_TOKEN","token_type":"bearer","expires_in":3600}⏎
```

### Using a Tooken

**Sample GET**

```
curl -H "Authorization: Bearer NEW_TOKEN_HERE" -X GET "http://your-server/ords/wmgt/api/tournament/votes"
```

**Sample POST**

```
curl -H "Authorization: Bearer NEW_TOKEN_HERE" -X POST "http://your-server/ords/wmgt/api/tournament/register" \
                                                          -H "Content-Type: application/json" 
```


### Securing ORDS Endpoints

Reference:
https://apexapplab.dev/2021/09/06/ords-apex-and-secure-rest-apis-part-1/
https://www.youtube.com/watch?v=5P3nx-OLxek


1. Create a Role and Priviledge and secure an end-point via pattern

```
begin
 
    ORDS.create_role(p_role_name  => 'WMGT_DISCORD_BOT_ROLE');

    ORDS.create_privilege(
        p_name          => 'wmgt.api.priv',
        p_role_name     => 'WMGT_DISCORD_BOT_ROLE',
        p_label         => 'WMGT API handling priv',
        p_description   => 'WMGT API handling priv');

    ORDS.create_privilege_mapping(
        p_privilege_name => 'wmgt.api.priv',
        p_pattern        => '/leaderboards/*');     
         
    commit;
 
end;
/
```

2. Setup user credentials with the desired priviledge. Notice the `grant_type` of `client_credentials`

```
begin
 
  OAUTH.create_client(
    p_name            => 'WMGTBOT',
    p_grant_type      => 'client_credentials',
    p_owner           => 'MyWMGT',
    -- p_description     => 'A client for API integrations by the Big Partner Company',
    p_support_email   => '&contact_email.',
    p_privilege_names => 'wmgt.api.priv'
  );
 
  OAUTH.grant_client_role(
    p_client_name     => 'WMGTBOT',
    p_role_name       => 'WMGT_DISCORD_BOT_ROLE'
  );
 
  commit;
 
end;
/
```

3. Obtain the client_id and secret from `user_ords_clients`

```
select client_id, client_secret
from user_ords_clients
/
```
