pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

abstract contract ApproverRole {
    using Roles for Roles.Role;

    event ApproverAdded(address indexed account);
    event ApproverRemoved(address indexed account);

    Roles.Role private _approvers;

    address firstSignAddress;
    address secondSignAddress;

    mapping(address => bool) signed; // Signed flag

     constructor() internal {
        _addApprover(msg.sender);
        firstSignAddress = 0x4d7AB40b8601af760927624200BC5bcD2837BB41; // You should change this address to your first sign address
        secondSignAddress = 0xD878E8726fbCaE338B3E184aa816F0fFD459d3c6; // You should change this address to your second sign address
    }

    modifier onlyApprover() {
        require(isApprover(msg.sender));
        _;
    }

    function sign() external {
        require(
            msg.sender == firstSignAddress || msg.sender == secondSignAddress
        );
        require(!signed[msg.sender]);
        signed[msg.sender] = true;
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.has(account);
    }

    function addApprover(address account) external onlyApprover {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _addApprover(account);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function removeApprover(address account) external onlyApprover {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _removeApprover(account);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function renounceApprover() external {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _removeApprover(msg.sender);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function _addApprover(address account) internal {
        _approvers.add(account);
        emit ApproverAdded(account);
    }

    function _removeApprover(address account) internal {
        _approvers.remove(account);
        emit ApproverRemoved(account);
    }
}


contract TokenBase is ERC20, ApproverRole {
  address public admin;

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    admin = msg.sender;
  }

  function updateAdmin(address newAdmin) external onlyApprover {
    admin = newAdmin;
  }

  function mint(address to, uint amount) external {
    require(msg.sender == admin, 'only admin');
    _mint(to, amount);
  }

  function burn(address owner, uint amount) external {
    require(msg.sender == admin, 'only admin');
    _burn(owner, amount);
  }
}