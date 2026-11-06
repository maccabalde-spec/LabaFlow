path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# The Python script wrote \` (escaped backtick) which is invalid in JS
# Replace the whole refreshMsgUI inner template with clean version
old = """      msgList.innerHTML=`
        <div style="padding:10px 13px;font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--border);">Customers</div>
        ${users.map(u=>{
          const thread=msgs.filter(m=>m.fromId===u.id||m.toId===u.id);
          const last=thread.length?thread[thread.length-1]:null;
          const unread=msgs.filter(m=>m.fromId===u.id&&!m.read).length;
          return \\`<div class="msg-list-item\\${activeMsgCustId===u.id?' active':''}" onclick="selectMsgCust(\\${u.id})">
            \\${unread?\\`<span class="ml-unread">\\${unread}</span>\\`:''}
            <div class="ml-name">\\${u.name}</div>
            <div class="ml-preview">\\${last?last.text:'No messages yet'}</div>
          </div>\\`;
        }).join('')||'<div class="empty" style="padding:20px;">No customers yet</div>'}
      `;"""

new = """      /* Rebuild customer list HTML directly — simpler approach */
      const listHTML2=users.map(u=>{
        const thread=msgs.filter(m=>m.fromId===u.id||m.toId===u.id);
        const last=thread.length?thread[thread.length-1]:null;
        const unread=msgs.filter(m=>m.fromId===u.id&&!m.read).length;
        return '<div class="msg-list-item'+(activeMsgCustId===u.id?' active':'')+'" onclick="selectMsgCust('+u.id+')">'
          +(unread?'<span class="ml-unread">'+unread+'</span>':'')
          +'<div class="ml-name">'+u.name+'</div>'
          +'<div class="ml-preview">'+(last?last.text:'No messages yet')+'</div>'
          +'</div>';
      }).join('');
      msgList.innerHTML='<div style="padding:10px 13px;font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--border);">Customers</div>'
        +(listHTML2||'<div class="empty" style="padding:20px;">No customers yet</div>');"""

if old in content:
    content = content.replace(old, new)
    print("✓ Fixed: refreshMsgUI template literal backtick escaping")
else:
    print("Not found exactly — trying raw escape fix...")
    # Just remove all \` → ` in that block
    import re
    # Find the refreshMsgUI function and fix backslash-backticks
    content = content.replace('\\`', '`')
    print("✓ Fixed: removed all \\` → ` in JS")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
