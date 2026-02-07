

let activeModals = [];

const createModal = (options = {}) => {
  const {
    title = 'Modal',
    content = '',
    size = 'md', 
    showCloseButton = true,
    closeOnBackdrop = true,
    onClose = null,
    footer = null
  } = options;
  

  const backdrop = document.createElement('div');
  backdrop.className = 'modal-backdrop';
  backdrop.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 1040;
    display: flex;
    align-items: center;
    justify-content: center;
    animation: fadeIn 0.15s ease;
  `;
  
  const modal = document.createElement('div');
  modal.className = `modal modal-${size}`;
  
  const sizes = {
    sm: '400px',
    md: '600px',
    lg: '800px',
    xl: '1000px'
  };
  
  modal.style.cssText = `
    background: white;
    border-radius: 1rem;
    max-width: ${sizes[size] || sizes.md};
    width: 90%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    animation: slideInUp 0.3s ease;
  `;
  
  const header = document.createElement('div');
  header.className = 'modal-header';
  header.style.cssText = `
    padding: 1.5rem;
    border-bottom: 1px solid var(--color-gray-300);
    display: flex;
    align-items: center;
    justify-content: space-between;
  `;
  
  const titleEl = document.createElement('h3');
  titleEl.className = 'modal-title';
  titleEl.textContent = title;
  titleEl.style.cssText = `
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0;
  `;
  
  header.appendChild(titleEl);
  
  if (showCloseButton) {
    const closeBtn = document.createElement('button');
    closeBtn.className = 'modal-close';
    closeBtn.innerHTML = '<i class="bi bi-x"></i>';
    closeBtn.style.cssText = `
      background: none;
      border: none;
      font-size: 1.5rem;
      cursor: pointer;
      color: var(--color-gray-600);
      padding: 0;
      width: 2rem;
      height: 2rem;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 0.5rem;
      transition: all 0.15s ease;
    `;
    
    closeBtn.addEventListener('click', () => closeModal(backdrop, onClose));
    header.appendChild(closeBtn);
  }
  
  const body = document.createElement('div');
  body.className = 'modal-body';
  body.style.padding = '1.5rem';
  
  if (typeof content === 'string') {
    body.innerHTML = content;
  } else {
    body.appendChild(content);
  }
  
  let footerEl = null;
  if (footer) {
    footerEl = document.createElement('div');
    footerEl.className = 'modal-footer';
    footerEl.style.cssText = `
      padding: 1rem 1.5rem;
      border-top: 1px solid var(--color-gray-300);
      display: flex;
      gap: 0.75rem;
      justify-content: flex-end;
    `;
    
    if (typeof footer === 'string') {
      footerEl.innerHTML = footer;
    } else {
      footerEl.appendChild(footer);
    }
  }
  
  modal.appendChild(header);
  modal.appendChild(body);
  if (footerEl) modal.appendChild(footerEl);
  
  backdrop.appendChild(modal);
  
  if (closeOnBackdrop) {
    backdrop.addEventListener('click', (e) => {
      if (e.target === backdrop) {
        closeModal(backdrop, onClose);
      }
    });
  }
  
  backdrop.addEventListener('click', (e) => {
    if (e.target && e.target.hasAttribute('data-modal-close')) {
      closeModal(backdrop, onClose);
    }
  });
  
  document.body.style.overflow = 'hidden';
  document.body.style.paddingRight = 'var(--scrollbar-width, 0px)';
  

  document.body.appendChild(backdrop);
  activeModals.push(backdrop);
  

  return {
    backdrop,
    modal,
    body,
    close: () => closeModal(backdrop, onClose)
  };
};


const closeModal = (backdrop, onClose = null) => {
  if (!backdrop) return;
  

  if (backdrop.dataset.closing === 'true') return;
  backdrop.dataset.closing = 'true';
  
  const modal = backdrop.querySelector('.modal');
  

  backdrop.style.animation = 'fadeOut 0.2s ease forwards';
  if (modal) modal.style.animation = 'slideOutDown 0.2s ease forwards';
  
  setTimeout(() => {
    if (backdrop && backdrop.parentNode) {
      backdrop.remove();
    }
    activeModals = activeModals.filter(m => m !== backdrop);
    

    if (activeModals.length === 0) {
      document.body.style.overflow = '';
      document.body.style.paddingRight = '';
    }
    
    if (onClose) onClose();
  }, 200);
};


const closeAllModals = () => {
  activeModals.forEach(backdrop => closeModal(backdrop));
};


if (!document.getElementById('modal-animations')) {
  const style = document.createElement('style');
  style.id = 'modal-animations';
  style.textContent = `
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    
    @keyframes fadeOut {
      from { opacity: 1; }
      to { opacity: 0; }
    }
    
    @keyframes slideInUp {
      from {
        transform: translateY(20px);
        opacity: 0;
      }
      to {
        transform: translateY(0);
        opacity: 1;
      }
    }
    
    @keyframes slideOutDown {
      from {
        transform: translateY(0);
        opacity: 1;
      }
      to {
        transform: translateY(20px);
        opacity: 0;
      }
    }
    
    .modal-close:hover {
      background-color: var(--color-gray-200) !important;
      color: var(--color-dark) !important;
    }
  `;
  document.head.appendChild(style);
}

export {
  createModal,
  closeModal,
  closeAllModals
};