# factory is to create exchange if the token does not has an exchange already

interface Exchange():
    def setup(token_addr: address): modifying

event NewExchange:
    token: indexed(address)
    exchange: indexed(address)

# The keyword `public` makes variables accessible from outside a contract
exchangeTemplate: public(address)
tokenCount: public(uint256)
# one to one relationship between token and exchange
token_to_exchange: HashMap[address, address]
exchange_to_token: HashMap[address, address]
id_to_token: HashMap[uint256, address]

@public
def initializeFactory(template: address):
    # ensure exchangeTemplate is not initialized yet
    assert self.exchangeTemplate == ZERO_ADDRESS
    assert template != ZERO_ADDRESS
    # exchangeTemplates is the address of the deployed uniswap_exchange code
    self.exchangeTemplate = template

# create exchange for a token
@public
def createExchange(token: address) -> address:
    # valid address, valid template
    # ensure token_to_exchange is not initialized -> the token does not have an exchange yet
    assert token != ZERO_ADDRESS
    assert self.exchangeTemplate != ZERO_ADDRESS
    assert self.token_to_exchange[token] == ZERO_ADDRESS

    # create_with_code duplicates a contract’s code and deploys it as a new instance
    # exchangeTemplate is the address of the contract to duplicate.
    exchange: address = create_with_code_of(self.exchangeTemplate)
    Exchange(exchange).setup(token)

    # establish one to one relationship
    self.token_to_exchange[token] = exchange
    self.exchange_to_token[exchange] = token

    # the factory keeps track of the number of exchange created, which is also
    # the id of the token/ exchange
    token_id: uint256 = self.tokenCount + 1
    self.tokenCount = token_id
    self.id_to_token[token_id] = token

    log NewExchange(token, exchange)
    return exchange

@public
@constant
def getExchange(token: address) -> address:
    return self.token_to_exchange[token]

@public
@constant
def getToken(exchange: address) -> address:
    return self.exchange_to_token[exchange]

@public
@constant
def getTokenWithId(token_id: uint256) -> address:
    return self.id_to_token[token_id]
