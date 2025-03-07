# SPDX-License-Identifier: BUSL-1.1
# @version ^0.3.6

# @title Velodrome Finance LP Sugar v3
# @author stas, ethzoomer
# @notice Makes it nicer to work with the liquidity pools.

# Structs

MAX_FACTORIES: constant(uint256) = 10
MAX_POOLS: constant(uint256) = 2000
MAX_TOKENS: constant(uint256) = 2000
MAX_LPS: constant(uint256) = 500
MAX_EPOCHS: constant(uint256) = 200
MAX_REWARDS: constant(uint256) = 50
MAX_POSITIONS: constant(uint256) = 100
WEEK: constant(uint256) = 7 * 24 * 60 * 60

# Slot0 from CLPool.sol
struct Slot:
  sqrtPriceX96: uint160
  tick: int24
  observationIndex: uint16
  cardinality: uint16
  cardinalityNext: uint16
  unlocked: bool

# GaugeFees from CLPool.sol
struct GaugeFees:
  token0: uint128
  token1: uint128

struct Amounts:
  amount0: uint256
  amount1: uint256

# Position from NonfungiblePositionManager.sol (NFT)
struct PositionData:
  nonce: uint96
  operator: address
  token0: address
  token1: address
  tickSpacing: uint24
  tickLower: int24
  tickUpper: int24
  liquidity: uint128
  feeGrowthInside0LastX128: uint256
  feeGrowthInside1LastX128: uint256
  tokensOwed0: uint128
  tokensOwed1: uint128

struct Position:
  id: uint256 # NFT ID on CL, 0 on v2
  lp: address
  liquidity: uint256 # Liquidity amount on CL, amount of LP tokens on v2
  staked: uint256 # liq amount staked on CL, amount of staked LP tokens on v2
  amount0: uint256 # amount of unstaked token0 on both v2 and CL
  amount1: uint256 # amount of unstaked token1 on both v2 and CL
  staked0: uint256 # amount of staked token0 on both v2 and CL
  staked1: uint256 # amount of staked token1 on both v2 and CL
  unstaked_earned0: uint256 # unstaked token0 fees earned on both v2 and CL
  unstaked_earned1: uint256 # unstaked token1 fees earned on both v2 and CL
  emissions_earned: uint256 # staked liq emissions earned on both v2 and CL
  tick_lower: int24 # Position lower tick on CL, 0 on v2
  tick_upper: int24 # Position upper tick on CL, 0 on v2
  sqrt_ratio_lower: uint160 # sqrtRatio at lower tick on CL, 0 on v2
  sqrt_ratio_upper: uint160 # sqrtRatio at upper tick on CL, 0 on v2

struct Token:
  token_address: address
  symbol: String[100]
  decimals: uint8
  account_balance: uint256
  listed: bool

struct SwapLp:
  lp: address
  type: int24 # tick spacing on CL, 0/-1 for stable/volatile on v2
  token0: address
  token1: address
  factory: address
  pool_fee: uint256

struct Lp:
  lp: address
  symbol: String[100]
  decimals: uint8
  liquidity: uint256

  type: int24 # tick spacing on CL, 0/-1 for stable/volatile on v2
  tick: int24 # current tick on CL, 0 on v2
  sqrt_ratio: uint160 # current sqrtRatio on CL, 0 on v2

  token0: address
  reserve0: uint256
  staked0: uint256

  token1: address
  reserve1: uint256
  staked1: uint256

  gauge: address
  gauge_liquidity: uint256
  gauge_alive: bool

  fee: address
  bribe: address
  factory: address

  emissions: uint256
  emissions_token: address

  pool_fee: uint256 # staked fee % on CL, fee % on v2
  unstaked_fee: uint256 # unstaked fee % on CL, 0 on v2
  token0_fees: uint256
  token1_fees: uint256

struct LpEpochReward:
  token: address
  amount: uint256

struct LpEpoch:
  ts: uint256
  lp: address
  votes: uint256
  emissions: uint256
  bribes: DynArray[LpEpochReward, MAX_REWARDS]
  fees: DynArray[LpEpochReward, MAX_REWARDS]

struct Reward:
  venft_id: uint256
  lp: address
  amount: uint256
  token: address
  fee: address
  bribe: address


# Our contracts / Interfaces

interface IERC20:
  def decimals() -> uint8: view
  def symbol() -> String[100]: view
  def balanceOf(_account: address) -> uint256: view

interface IFactoryRegistry:
  def fallbackPoolFactory() -> address: view
  def poolFactories() -> DynArray[address, MAX_FACTORIES]: view
  def poolFactoriesLength() -> uint256: view

interface IPoolFactory:
  def allPoolsLength() -> uint256: view
  def allPools(_index: uint256) -> address: view
  def getFee(_pool_addr: address, _stable: bool) -> uint256: view
  def getPool(_token0: address, _token1: address, _fee: int24) -> address: view

interface IPool:
  def token0() -> address: view
  def token1() -> address: view
  def reserve0() -> uint256: view
  def reserve1() -> uint256: view
  def claimable0(_account: address) -> uint256: view
  def claimable1(_account: address) -> uint256: view
  def supplyIndex0(_account: address) -> uint256: view
  def supplyIndex1(_account: address) -> uint256: view
  def index0() -> uint256: view
  def index1() -> uint256: view
  def totalSupply() -> uint256: view
  def symbol() -> String[100]: view
  def decimals() -> uint8: view
  def stable() -> bool: view
  def balanceOf(_account: address) -> uint256: view
  def poolFees() -> address: view
  def gauge() -> address: view # fetches gauge from CL pool
  def tickSpacing() -> int24: view # CL tick spacing
  def slot0() -> Slot: view # CL slot data
  def gaugeFees() -> GaugeFees: view # CL gauge fees amounts
  def fee() -> uint24: view # CL fee level
  def unstakedFee() -> uint24: view # CL unstaked fee level
  def liquidity() -> uint128: view # CL active liquidity
  def stakedLiquidity() -> uint128: view # CL active staked liquidity

interface IVoter:
  def gauges(_pool_addr: address) -> address: view
  def gaugeToBribe(_gauge_addr: address) -> address: view
  def gaugeToFees(_gauge_addr: address) -> address: view
  def isAlive(_gauge_addr: address) -> bool: view
  def isWhitelistedToken(_token_addr: address) -> bool: view

interface IGauge:
  def fees0() -> uint256: view
  def fees1() -> uint256: view
  def earned(_account: address) -> uint256: view
  def balanceOf(_account: address) -> uint256: view
  def totalSupply() -> uint256: view
  def rewardRate() -> uint256: view
  def rewardRateByEpoch(_ts: uint256) -> uint256: view
  def rewardToken() -> address: view
  def periodFinish() -> uint256: view

interface ICLGauge:
  def earned(_account: address, _position_id: uint256) -> uint256: view
  def rewards(_position_id: uint256) -> uint256: view
  def rewardRate() -> uint256: view
  def rewardRateByEpoch(_ts: uint256) -> uint256: view
  def rewardToken() -> address: view
  def feesVotingReward() -> address: view
  def stakedContains(_account: address, _position_id: uint256) -> bool: view
  def stakedValues(_account: address) -> DynArray[uint256, MAX_POSITIONS]: view
  def periodFinish() -> uint256: view

interface INFPositionManager:
  def positions(_position_id: uint256) -> PositionData: view
  def tokenOfOwnerByIndex(_account: address, _index: uint256) -> uint256: view
  def balanceOf(_account: address) -> uint256: view

interface IReward:
  def getPriorSupplyIndex(_ts: uint256) -> uint256: view
  def supplyCheckpoints(_index: uint256) -> uint256[2]: view
  def tokenRewardsPerEpoch(_token: address, _epstart: uint256) -> uint256: view
  def rewardsListLength() -> uint256: view
  def rewards(_index: uint256) -> address: view
  def earned(_token: address, _venft_id: uint256) -> uint256: view

interface ISlipstreamHelper:
  def getAmountsForLiquidity(_ratio: uint160, _ratioA: uint160, _ratioB: uint160, _liquidity: uint128) -> Amounts: view
  def getSqrtRatioAtTick(_tick: int24) -> uint160: view
  def principal(_nfpm: address, _position_id: uint256, _ratio: uint160) -> Amounts: view
  def fees(_nfpm: address, _position_id: uint256) -> Amounts: view
  def poolFees(_pool: address, _liquidity: uint128, _current_tick: int24, _lower_tick: int24, _upper_tick: int24) -> Amounts: view

# Vars
registry: public(IFactoryRegistry)
voter: public(IVoter)
convertor: public(address)
nfpm: public(INFPositionManager)
cl_helper: public(ISlipstreamHelper)

# Methods

@external
def __init__(_voter: address, _registry: address, _convertor: address, \
    _nfpm: address, _slipstream_helper: address):
  """
  @dev Sets up our external contract addresses
  """
  self.voter = IVoter(_voter)
  self.registry = IFactoryRegistry(_registry)
  self.nfpm = INFPositionManager(_nfpm)
  self.convertor = _convertor
  self.cl_helper = ISlipstreamHelper(_slipstream_helper)

@internal
@view
def _pools(_limit: uint256, _offset: uint256)\
    -> DynArray[address[4], MAX_POOLS]:
  """
  @param _limit The max amount of pools to return
  @param _offset The amount of pools to skip (for optimization)
  @notice Returns a compiled list of pool and its factory and gauge
  @return Array of four addresses (factory, pool, gauge, type value: 0/2/3)
  """
  factories: DynArray[address, MAX_FACTORIES] = self.registry.poolFactories()
  factories_count: uint256 = len(factories)

  placeholder: address[4] = empty(address[4])
  to_skip: uint256 = _offset

  pools: DynArray[address[4], MAX_POOLS] = \
    empty(DynArray[address[4], MAX_POOLS])

  for index in range(0, MAX_FACTORIES):
    if index >= factories_count:
      break

    factory_type: address = empty(address)
    factory: IPoolFactory = IPoolFactory(factories[index])

    if self._is_v2_factory(factory.address):
      factory_type = convert(2, address)
    if self._is_cl_factory(factory.address):
      factory_type = convert(3, address)

    if factory_type == empty(address):
      continue

    pools_count: uint256 = factory.allPoolsLength()

    for pindex in range(0, MAX_POOLS):
      if pindex >= pools_count or len(pools) >= _limit + _offset:
        break

      # Since the convertor pool, first pool on one of the factories...
      if pindex == 0 and factory.allPools(0) == self.convertor:
        continue

      # Basically skip calls for offset records...
      if to_skip > 0:
        to_skip -= 1
        pools.append(placeholder)
        continue

      pool_addr: address = factory.allPools(pindex)
      gauge_addr: address = self.voter.gauges(pool_addr)

      pools.append([factory.address, pool_addr, gauge_addr, factory_type])

  return pools

@external
@view
def forSwaps(_limit: uint256, _offset: uint256) -> DynArray[SwapLp, MAX_POOLS]:
  """
  @notice Returns a compiled list of pools for swaps from pool factories (sans v1)
  @param _limit The max amount of pools to process
  @param _offset The amount of pools to skip
  @return `SwapLp` structs
  """
  factories: DynArray[address, MAX_FACTORIES] = self.registry.poolFactories()
  factories_count: uint256 = len(factories)

  pools: DynArray[SwapLp, MAX_POOLS] = empty(DynArray[SwapLp, MAX_POOLS])
  to_skip: uint256 = _offset
  left: uint256 = _limit

  for index in range(0, MAX_FACTORIES):
    if index >= factories_count:
      break

    factory: IPoolFactory = IPoolFactory(factories[index])
    is_cl_factory: bool = self._is_cl_factory(factory.address)
    is_v2_factory: bool = self._is_v2_factory(factory.address)

    if is_v2_factory == False and is_cl_factory == False:
      continue

    pools_count: uint256 = factory.allPoolsLength()

    for pindex in range(0, MAX_POOLS):
      if pindex >= pools_count:
        break

      # If no pools to process are left...
      if left == 0:
        break

      # Basically skip calls for offset records...
      if to_skip > 0:
        to_skip -= 1
        continue
      else:
        left -= 1

      pool_addr: address = factory.allPools(pindex)
      pool: IPool = IPool(pool_addr)
      type: int24 = -1
      token0: address = pool.token0()
      token1: address = pool.token1()
      reserve0: uint256 = 0
      pool_fee: uint256 = 0

      if is_cl_factory:
        type = pool.tickSpacing()
        reserve0 = IERC20(token0).balanceOf(pool_addr)
        pool_fee = convert(pool.fee(), uint256)
      else:
        if pool.stable():
          type = 0
        reserve0 = pool.reserve0()
        pool_fee = factory.getFee(pool_addr, (type == 0))

      if reserve0 > 0:
        pools.append(SwapLp({
          lp: pool_addr,
          type: type,
          token0: token0,
          token1: token1,
          factory: factory.address,
          pool_fee: pool_fee
        }))

  return pools

@external
@view
def tokens(_limit: uint256, _offset: uint256, _account: address, \
    _addresses: DynArray[address, MAX_TOKENS]) -> DynArray[Token, MAX_TOKENS]:
  """
  @notice Returns a collection of tokens data based on available pools
  @param _limit The max amount of tokens to return
  @param _offset The amount of pools to skip
  @param _account The account to check the balances
  @return Array for Token structs
  """
  pools: DynArray[address[4], MAX_POOLS] = self._pools(_limit, _offset)

  pools_count: uint256 = len(pools)
  addresses_count: uint256 = len(_addresses)
  col: DynArray[Token, MAX_TOKENS] = empty(DynArray[Token, MAX_TOKENS])
  seen: DynArray[address, MAX_TOKENS] = empty(DynArray[address, MAX_TOKENS])

  for index in range(0, MAX_TOKENS):
    if len(col) >= _limit or index >= addresses_count:
      break

    col.append(self._token(_addresses[index], _account))
    seen.append(_addresses[index])

  for index in range(_offset, _offset + MAX_TOKENS):
    if len(col) >= _limit or index >= pools_count:
      break

    pool_data: address[4] = pools[index]

    pool: IPool = IPool(pool_data[1])
    token0: address = pool.token0()
    token1: address = pool.token1()

    if token0 not in seen:
      col.append(self._token(token0, _account))
      seen.append(token0)

    if token1 not in seen:
      col.append(self._token(token1, _account))
      seen.append(token1)

  return col

@internal
@view
def _token(_address: address, _account: address) -> Token:
  token: IERC20 = IERC20(_address)
  bal: uint256 = empty(uint256)

  if _account != empty(address):
    bal = token.balanceOf(_account)

  return Token({
    token_address: _address,
    symbol: token.symbol(),
    decimals: token.decimals(),
    account_balance: bal,
    listed: self.voter.isWhitelistedToken(_address)
  })

@external
@view
def all(_limit: uint256, _offset: uint256) -> DynArray[Lp, MAX_LPS]:
  """
  @notice Returns a collection of pool data
  @param _limit The max amount of pools to return
  @param _offset The amount of pools to skip
  @return Array for Lp structs
  """
  col: DynArray[Lp, MAX_LPS] = empty(DynArray[Lp, MAX_LPS])
  pools: DynArray[address[4], MAX_POOLS] = self._pools(_limit, _offset)
  pools_count: uint256 = len(pools)

  for index in range(_offset, _offset + MAX_POOLS):
    if len(col) == _limit or index >= pools_count:
      break

    pool_data: address[4] = pools[index]
    pool: IPool = IPool(pool_data[1])
    token0: address = pool.token0()
    token1: address = pool.token1()

    # If this is a CL factory...
    if convert(3, address) == pool_data[3]:
      col.append(self._cl_lp(pool_data, token0, token1))
    else:
      col.append(self._v2_lp(pool_data, token0, token1))

  return col

@external
@view
def byIndex(_index: uint256) -> Lp:
  """
  @notice Returns pool data at a specific stored index
  @param _index The index to lookup
  @return Lp struct
  """
  # Basically index is the limit and the offset is always one...
  # This will fire if _index is out of bounds
  pool_data: address[4] = self._pools(1, _index)[_index]
  pool: IPool = IPool(pool_data[1])
  token0: address = pool.token0()
  token1: address = pool.token1()

  # If this is a CL factory...
  if convert(3, address) == pool_data[3]:
    return self._cl_lp(pool_data, token0, token1)

  return self._v2_lp(pool_data, token0, token1)

@internal
@view
def _v2_lp(_data: address[4], _token0: address, _token1: address) -> Lp:
  """
  @notice Returns pool data based on the factory, pool and gauge addresses
  @param _address The addresses to lookup
  @return Lp struct
  """
  pool: IPool = IPool(_data[1])
  gauge: IGauge = IGauge(_data[2])

  earned: uint256 = 0
  acc_staked: uint256 = 0
  pool_liquidity: uint256 = pool.totalSupply()
  gauge_liquidity: uint256 = 0
  emissions: uint256 = 0
  emissions_token: address = empty(address)
  is_stable: bool = pool.stable()
  pool_fee: uint256 = IPoolFactory(_data[0]).getFee(pool.address, is_stable)
  pool_fees: address = pool.poolFees()
  token0: IERC20 = IERC20(_token0)
  token1: IERC20 = IERC20(_token1)
  token0_fees: uint256 = token0.balanceOf(pool_fees)
  token1_fees: uint256 = token1.balanceOf(pool_fees)
  gauge_alive: bool = self.voter.isAlive(gauge.address)
  decimals: uint8 = pool.decimals()
  claimable0: uint256 = 0
  claimable1: uint256 = 0
  acc_balance: uint256 = 0
  reserve0: uint256 = pool.reserve0()
  reserve1: uint256 = pool.reserve1()
  staked0: uint256 = 0
  staked1: uint256 = 0
  type: int24 = -1

  if is_stable:
    type = 0

  if gauge.address != empty(address):
    gauge_liquidity = gauge.totalSupply()
    emissions_token = gauge.rewardToken()

  if gauge_alive and gauge.periodFinish() > block.timestamp:
    emissions = gauge.rewardRate()
    if gauge_liquidity > 0:
      token0_fees = (pool.claimable0(_data[2]) * pool_liquidity) / gauge_liquidity
      token1_fees = (pool.claimable1(_data[2]) * pool_liquidity) / gauge_liquidity
      staked0 = (reserve0 * gauge_liquidity) / pool_liquidity
      staked1 = (reserve1 * gauge_liquidity) / pool_liquidity

  return Lp({
    lp: _data[1],
    symbol: pool.symbol(),
    decimals: decimals,
    liquidity: pool_liquidity,

    type: type,
    tick: 0,
    sqrt_ratio: 0,

    token0: token0.address,
    reserve0: reserve0,
    staked0: staked0,

    token1: token1.address,
    reserve1: reserve1,
    staked1: staked1,

    gauge: gauge.address,
    gauge_liquidity: gauge_liquidity,
    gauge_alive: gauge_alive,

    fee: self.voter.gaugeToFees(gauge.address),
    bribe: self.voter.gaugeToBribe(gauge.address),
    factory: _data[0],

    emissions: emissions,
    emissions_token: emissions_token,

    pool_fee: pool_fee,
    unstaked_fee: 0,
    token0_fees: token0_fees,
    token1_fees: token1_fees,
  })

@external
@view
def positions(_limit: uint256, _offset: uint256, _account: address)\
    -> DynArray[Position, MAX_POSITIONS]:
  """
  @notice Returns a collection of positions
  @param _account The account to fetch positions for
  @param _limit The max amount of pools to process
  @param _offset The amount of pools to skip (for optimization)
  @return Array for Lp structs
  """
  positions: DynArray[Position, MAX_POSITIONS] = \
    empty(DynArray[Position, MAX_POSITIONS])

  if _account == empty(address):
    return positions

  to_skip: uint256 = _offset
  pools_done: uint256 = 0

  factories: DynArray[address, MAX_FACTORIES] = self.registry.poolFactories()
  factories_count: uint256 = len(factories)

  for index in range(0, MAX_FACTORIES):
    if index >= factories_count:
      break

    factory: IPoolFactory = IPoolFactory(factories[index])

    if self._is_v2_factory(factory.address):
      pools_count: uint256 = factory.allPoolsLength()

      for pindex in range(0, MAX_POOLS):
        if pindex >= pools_count or pools_done >= _limit:
          break

        # Basically skip calls for offset records...
        if to_skip > 0:
          to_skip -= 1
          continue
        else:
          pools_done += 1

        pool_addr: address = factory.allPools(pindex)

        if pool_addr == self.convertor:
          continue

        pos: Position = self._v2_position(_account, pool_addr)

        if pos.lp != empty(address):
          positions.append(pos)

    if self._is_cl_factory(factory.address):
      # fetch unstaked CL positions
      positions_count: uint256 = self.nfpm.balanceOf(_account)

      for pindex in range(0, MAX_POSITIONS):
        if pindex >= positions_count or pools_done >= _limit:
          break

        # Basically skip calls for offset records...
        if to_skip > 0:
          to_skip -= 1
          continue
        else:
          pools_done += 1

        pos_id: uint256 = self.nfpm.tokenOfOwnerByIndex(_account, pindex)
        pos: Position = self._cl_position(
          pos_id,
          _account,
          empty(address),
          empty(address),
          factory.address
        )

        if pos.lp != empty(address):
          positions.append(pos)

      # fetch staked CL positions
      pools_count: uint256 = factory.allPoolsLength()

      for pindex in range(0, MAX_POOLS):
        if pindex >= pools_count or pools_done >= _limit:
          break

        # Basically skip calls for offset records...
        if to_skip > 0:
          to_skip -= 1
          continue
        else:
          pools_done += 1

        pool_addr: address = factory.allPools(pindex)
        gauge: ICLGauge = ICLGauge(self.voter.gauges(pool_addr))

        if gauge.address == empty(address):
          continue

        staked_position_ids: DynArray[uint256, MAX_POSITIONS] = gauge.stakedValues(_account)

        for sindex in range(0, MAX_POSITIONS):
          if sindex >= len(staked_position_ids):
            break

          pos: Position = self._cl_position(
            staked_position_ids[sindex],
            _account,
            pool_addr,
            gauge.address,
            factory.address
          )

          positions.append(pos)

  return positions

@internal
@view
def _cl_position(_id: uint256, _account: address,\
    _pool:address, _gauge:address, _factory: address) -> Position:
  """
  @notice Returns concentrated pool position data
  @param _id The token ID of the position
  @param _account The account to fetch positions for
  @param _pool The pool address
  @param _gauge The pool gauge address
  @param _factory The CL factory address
  @return A Position struct
  """
  pos: Position = empty(Position)
  pos.id = _id
  pos.lp = _pool

  data: PositionData = self.nfpm.positions(pos.id)

  # Try to find the pool if we're fetching an unstaked position
  if pos.lp == empty(address):
    pos.lp = IPoolFactory(_factory).getPool(
      data.token0,
      data.token1,
      convert(data.tickSpacing, int24)
    )

  if pos.lp == empty(address):
    return empty(Position)

  pool: IPool = IPool(pos.lp)
  gauge: ICLGauge = ICLGauge(_gauge)
  slot: Slot = pool.slot0()
  # If the _gauge is present, it's because we're fetching a staked position
  staked: bool = _gauge != empty(address)

  # Try to find the gauge if we're fetching an unstaked position
  if _gauge == empty(address):
    gauge = ICLGauge(self.voter.gauges(pos.lp))

  amounts: Amounts = self.cl_helper.principal(
    self.nfpm.address, pos.id, slot.sqrtPriceX96
  )
  pos.amount0 = amounts.amount0
  pos.amount1 = amounts.amount1

  pos.liquidity = convert(data.liquidity, uint256)
  pos.tick_lower = data.tickLower
  pos.tick_upper = data.tickUpper

  pos.sqrt_ratio_lower = self.cl_helper.getSqrtRatioAtTick(pos.tick_lower)
  pos.sqrt_ratio_upper = self.cl_helper.getSqrtRatioAtTick(pos.tick_upper)

  amounts_fees: Amounts = self.cl_helper.fees(self.nfpm.address, pos.id)
  pos.unstaked_earned0 = amounts_fees.amount0
  pos.unstaked_earned1 = amounts_fees.amount1

  if staked == False and gauge.address != empty(address):
    staked = gauge.stakedContains(_account, pos.id)

  if staked:
    pos.emissions_earned = gauge.earned(_account, pos.id) + gauge.rewards(pos.id)

  # Reverse the liquidity since a staked position uses full available liquidity
  if staked:
    pos.staked = pos.liquidity
    pos.staked0 = pos.amount0
    pos.staked1 = pos.amount1
    pos.amount0 = 0
    pos.amount1 = 0
    pos.liquidity = 0

  return pos

@internal
@view
def _v2_position(_account: address, _pool: address) -> Position:
  """
  @notice Returns v2 pool position data
  @param _account The account to fetch positions for
  @param _factory The pool address
  @return A Position struct
  """
  pool: IPool = IPool(_pool)
  gauge: IGauge = IGauge(self.voter.gauges(_pool))
  decimals: uint8 = pool.decimals()

  pos: Position = empty(Position)
  pos.lp = pool.address
  pos.liquidity = pool.balanceOf(_account)
  pos.unstaked_earned0 = pool.claimable0(_account)
  pos.unstaked_earned1 = pool.claimable1(_account)
  claimable_delta0: uint256 = pool.index0() - pool.supplyIndex0(_account)
  claimable_delta1: uint256 = pool.index1() - pool.supplyIndex1(_account)

  if claimable_delta0 > 0:
    pos.unstaked_earned0 += \
      (pos.liquidity * claimable_delta0) / 10**convert(decimals, uint256)
  if claimable_delta1 > 0:
    pos.unstaked_earned1 += \
      (pos.liquidity * claimable_delta1) / 10**convert(decimals, uint256)

  if gauge.address != empty(address):
    pos.staked = gauge.balanceOf(_account)
    pos.emissions_earned = gauge.earned(_account)

  if pos.liquidity + pos.staked + pos.emissions_earned + pos.unstaked_earned0 == 0:
    return empty(Position)

  pool_liquidity: uint256 = pool.totalSupply()
  reserve0: uint256 = pool.reserve0()
  reserve1: uint256 = pool.reserve1()

  pos.amount0 = (pos.liquidity * reserve0) / pool_liquidity
  pos.amount1 = (pos.liquidity * reserve1) / pool_liquidity
  pos.staked0 = (pos.staked * reserve0) / pool_liquidity
  pos.staked1 = (pos.staked * reserve1) / pool_liquidity

  return pos

@internal
@view
def _cl_lp(_data: address[4], _token0: address, _token1: address) -> Lp:
  """
  @notice Returns CL pool data based on the factory, pool and gauge addresses
  @param _data The addresses to lookup
  @param _account The user account
  @return Lp struct
  """
  pool: IPool = IPool(_data[1])
  gauge: ICLGauge = ICLGauge(_data[2])

  gauge_alive: bool = self.voter.isAlive(gauge.address)
  fee_voting_reward: address = empty(address)
  emissions: uint256 = 0
  emissions_token: address = empty(address)
  token0: IERC20 = IERC20(_token0)
  token1: IERC20 = IERC20(_token1)
  staked0: uint256 = 0
  staked1: uint256 = 0
  tick_spacing: int24 = pool.tickSpacing()
  pool_liquidity: uint128 = pool.liquidity()
  gauge_liquidity: uint128 = pool.stakedLiquidity()
  token0_fees: uint256 = 0
  token1_fees: uint256 = 0

  slot: Slot = pool.slot0()
  tick_low: int24 = slot.tick - tick_spacing
  tick_high: int24 = slot.tick + tick_spacing

  if gauge.address == empty(address) or gauge_liquidity == 0:
    unstaked_fees: Amounts = self.cl_helper.poolFees(
      pool.address, pool_liquidity, slot.tick, tick_low, tick_high
    )
    token0_fees = unstaked_fees.amount0
    token1_fees = unstaked_fees.amount1
  else:
    fee_voting_reward = gauge.feesVotingReward()
    emissions_token = gauge.rewardToken()

    ratio_a: uint160 = self.cl_helper.getSqrtRatioAtTick(tick_low)
    ratio_b: uint160 = self.cl_helper.getSqrtRatioAtTick(tick_high)
    staked_amounts: Amounts = self.cl_helper.getAmountsForLiquidity(
      slot.sqrtPriceX96, ratio_a, ratio_b, gauge_liquidity
    )
    staked0 = staked_amounts.amount0
    staked1 = staked_amounts.amount1

    # Estimate based on the ratio of staked liquidity...
    gauge_fees: GaugeFees = pool.gaugeFees()
    # Convert to uint256 first to prevent overflows
    token0_fees = (convert(gauge_fees.token0, uint256) * convert(pool_liquidity, uint256)) / convert(gauge_liquidity, uint256)
    token1_fees = (convert(gauge_fees.token1, uint256) * convert(pool_liquidity, uint256)) / convert(gauge_liquidity, uint256)

    if gauge_alive and gauge.periodFinish() > block.timestamp:
      emissions = gauge.rewardRate()

  return Lp({
    lp: pool.address,
    symbol: "",
    decimals: 18,
    liquidity: convert(pool_liquidity, uint256),

    type: tick_spacing,
    tick: slot.tick,
    sqrt_ratio: slot.sqrtPriceX96,

    token0: token0.address,
    reserve0: token0.balanceOf(pool.address) - token0_fees,
    staked0: staked0,

    token1: token1.address,
    reserve1: token1.balanceOf(pool.address) - token1_fees,
    staked1: staked1,

    gauge: gauge.address,
    gauge_liquidity: convert(gauge_liquidity, uint256),
    gauge_alive: gauge_alive,

    fee: fee_voting_reward,
    bribe: self.voter.gaugeToBribe(gauge.address),
    factory: _data[0],

    emissions: emissions,
    emissions_token: emissions_token,

    pool_fee: convert(pool.fee(), uint256),
    unstaked_fee: convert(pool.unstakedFee(), uint256),
    token0_fees: token0_fees,
    token1_fees: token1_fees
  })

@external
@view
def epochsLatest(_limit: uint256, _offset: uint256) \
    -> DynArray[LpEpoch, MAX_POOLS]:
  """
  @notice Returns all pools latest epoch data (up to 200 items)
  @param _limit The max amount of pools to check for epochs
  @param _offset The amount of pools to skip
  @return Array for LpEpoch structs
  """
  pools: DynArray[address[4], MAX_POOLS] = self._pools(_limit, _offset)
  pools_count: uint256 = len(pools)
  counted: uint256 = 0

  col: DynArray[LpEpoch, MAX_POOLS] = empty(DynArray[LpEpoch, MAX_POOLS])

  for index in range(_offset, _offset + MAX_POOLS):
    if counted == _limit or index >= pools_count:
      break

    pool_data: address[4] = pools[index]

    if self.voter.isAlive(pool_data[2]) == False:
      continue

    col.append(self._epochLatestByAddress(pool_data[1], pool_data[2]))

    counted += 1

  return col

@external
@view
def epochsByAddress(_limit: uint256, _offset: uint256, _address: address) \
    -> DynArray[LpEpoch, MAX_EPOCHS]:
  """
  @notice Returns all pool epoch data based on the address
  @param _limit The max amount of epochs to return
  @param _offset The number of epochs to skip
  @param _address The address to lookup
  @return Array for LpEpoch structs
  """
  return self._epochsByAddress(_limit, _offset, _address)

@internal
@view
def _epochLatestByAddress(_address: address, _gauge: address) -> LpEpoch:
  """
  @notice Returns latest pool epoch data based on the address
  @param _address The pool address
  @param _gauge The pool gauge
  @return A LpEpoch struct
  """
  gauge: IGauge = IGauge(_gauge)
  bribe: IReward = IReward(self.voter.gaugeToBribe(gauge.address))

  epoch_start_ts: uint256 = block.timestamp / WEEK * WEEK
  epoch_end_ts: uint256 = epoch_start_ts + WEEK - 1

  bribe_supply_cp: uint256[2] = bribe.supplyCheckpoints(
    bribe.getPriorSupplyIndex(epoch_end_ts)
  )

  return LpEpoch({
    ts: epoch_start_ts,
    lp: _address,
    votes: bribe_supply_cp[1],
    emissions: gauge.rewardRateByEpoch(epoch_start_ts),
    bribes: self._epochRewards(epoch_start_ts, bribe.address),
    fees: self._epochRewards(
      epoch_start_ts, self.voter.gaugeToFees(gauge.address)
    )
  })

@internal
@view
def _epochsByAddress(_limit: uint256, _offset: uint256, _address: address) \
    -> DynArray[LpEpoch, MAX_EPOCHS]:
  """
  @notice Returns all pool epoch data based on the address
  @param _limit The max amount of epochs to return
  @param _offset The number of epochs to skip
  @param _address The address to lookup
  @return Array for LpEpoch structs
  """
  assert _address != empty(address), 'Invalid address!'

  epochs: DynArray[LpEpoch, MAX_EPOCHS] = \
    empty(DynArray[LpEpoch, MAX_EPOCHS])

  gauge: IGauge = IGauge(self.voter.gauges(_address))

  if self.voter.isAlive(gauge.address) == False:
    return epochs

  bribe: IReward = IReward(self.voter.gaugeToBribe(gauge.address))

  curr_epoch_start_ts: uint256 = block.timestamp / WEEK * WEEK

  for weeks in range(_offset, _offset + MAX_EPOCHS):
    epoch_start_ts: uint256 = curr_epoch_start_ts - (weeks * WEEK)
    epoch_end_ts: uint256 = epoch_start_ts + WEEK - 1

    if len(epochs) == _limit or weeks >= MAX_EPOCHS:
      break

    bribe_supply_index: uint256 = bribe.getPriorSupplyIndex(epoch_end_ts)
    bribe_supply_cp: uint256[2] = bribe.supplyCheckpoints(bribe_supply_index)

    epochs.append(LpEpoch({
      ts: epoch_start_ts,
      lp: _address,
      votes: bribe_supply_cp[1],
      emissions: gauge.rewardRateByEpoch(epoch_start_ts),
      bribes: self._epochRewards(epoch_start_ts, bribe.address),
      fees: self._epochRewards(
        epoch_start_ts, self.voter.gaugeToFees(gauge.address)
      )
    }))

    # If we reach the last supply index...
    if bribe_supply_index == 0:
      break

  return epochs

@internal
@view
def _epochRewards(_ts: uint256, _reward: address) \
    -> DynArray[LpEpochReward, MAX_REWARDS]:
  """
  @notice Returns pool rewards
  @param _ts The pool epoch start timestamp
  @param _bribe The reward address
  @return An array of `LpEpochReward` structs
  """
  rewards: DynArray[LpEpochReward, MAX_REWARDS] = \
    empty(DynArray[LpEpochReward, MAX_REWARDS])

  if _reward == empty(address):
    return rewards

  reward: IReward = IReward(_reward)
  rewards_len: uint256 = reward.rewardsListLength()

  for rindex in range(MAX_REWARDS):
    if rindex >= rewards_len:
      break

    reward_token: address = reward.rewards(rindex)
    reward_amount: uint256 = reward.tokenRewardsPerEpoch(reward_token, _ts)

    if reward_amount == 0:
      continue

    rewards.append(LpEpochReward({
      token: reward_token,
      amount: reward_amount
    }))

  return rewards

@external
@view
def rewards(_limit: uint256, _offset: uint256, _venft_id: uint256) \
    -> DynArray[Reward, MAX_POOLS]:
  """
  @notice Returns a collection of veNFT rewards data
  @param _limit The max amount of pools to check for rewards
  @param _offset The amount of pools to skip checking for rewards
  @param _venft_id The veNFT ID to get rewards for
  @return Array for VeNFT Reward structs
  """
  pools: DynArray[address[4], MAX_POOLS] = self._pools(_limit, _offset)
  pools_count: uint256 = len(pools)
  counted: uint256 = 0

  col: DynArray[Reward, MAX_POOLS] = empty(DynArray[Reward, MAX_POOLS])

  for pindex in range(_offset, _offset + MAX_POOLS):
    if counted == _limit or pindex >= pools_count:
      break

    pool_data: address[4] = pools[pindex]
    pcol: DynArray[Reward, MAX_POOLS] = \
      self._poolRewards(_venft_id, pool_data[1], pool_data[2])

    # Basically merge pool rewards to the rest of the rewards...
    for cindex in range(MAX_POOLS):
      if cindex >= len(pcol):
        break

      col.append(pcol[cindex])

    counted += 1

  return col

@external
@view
def rewardsByAddress(_venft_id: uint256, _pool: address) \
    -> DynArray[Reward, MAX_POOLS]:
  """
  @notice Returns a collection of veNFT rewards data for a specific pool
  @param _venft_id The veNFT ID to get rewards for
  @param _pool The pool address to get rewards for
  @return Array for VeNFT Reward structs
  """
  gauge_addr: address = self.voter.gauges(_pool)

  return self._poolRewards(_venft_id, _pool, gauge_addr)

@internal
@view
def _poolRewards(_venft_id: uint256, _pool: address, _gauge: address) \
    -> DynArray[Reward, MAX_POOLS]:
  """
  @notice Returns a collection with veNFT pool rewards
  @param _venft_id The veNFT ID to get rewards for
  @param _pool The pool address
  @param _gauge The pool gauge address
  @param _col The array of `Reward` sturcts to update
  """
  pool: IPool = IPool(_pool)

  col: DynArray[Reward, MAX_POOLS] = empty(DynArray[Reward, MAX_POOLS])

  if _pool == empty(address) or _gauge == empty(address):
    return col

  fee: IReward = IReward(self.voter.gaugeToFees(_gauge))
  bribe: IReward = IReward(self.voter.gaugeToBribe(_gauge))

  token0: address = pool.token0()
  token1: address = pool.token1()

  fee0_amount: uint256 = fee.earned(token0, _venft_id)
  fee1_amount: uint256 = fee.earned(token1, _venft_id)

  if fee0_amount > 0:
    col.append(
      Reward({
        venft_id: _venft_id,
        lp: pool.address,
        amount: fee0_amount,
        token: token0,
        fee: fee.address,
        bribe: empty(address)
      })
    )

  if fee1_amount > 0:
    col.append(
      Reward({
        venft_id: _venft_id,
        lp: pool.address,
        amount: fee1_amount,
        token: token1,
        fee: fee.address,
        bribe: empty(address)
      })
    )

  if bribe.address == empty(address):
    return col

  bribes_len: uint256 = bribe.rewardsListLength()

  for bindex in range(MAX_REWARDS):
    if bindex >= bribes_len:
      break

    bribe_token: address = bribe.rewards(bindex)
    bribe_amount: uint256 = bribe.earned(bribe_token, _venft_id)

    if bribe_amount == 0:
      continue

    col.append(
      Reward({
        venft_id: _venft_id,
        lp: pool.address,
        amount: bribe_amount,
        token: bribe_token,
        fee: empty(address),
        bribe: bribe.address
      })
    )

  return col

@internal
@view
def _is_v2_factory(_factory: address) -> bool:
  """
  @notice Returns true if address is a v2 factory
  @param _factory The factory address
  """
  response: Bytes[32] = raw_call(
      _factory,
      method_id("ZERO_FEE_INDICATOR()"),
      max_outsize=32,
      is_delegate_call=False,
      is_static_call=True,
      revert_on_failure=False
  )[1]

  return len(response) > 0

@internal
@view
def _is_cl_factory(_factory: address) -> bool:
  """
  @notice Returns true if address is a CL factory
  @param _factory The factory address
  """
  response: Bytes[32] = raw_call(
      _factory,
      method_id("unstakedFeeModule()"),
      max_outsize=32,
      is_delegate_call=False,
      is_static_call=True,
      revert_on_failure=False
  )[1]

  return len(response) > 0
